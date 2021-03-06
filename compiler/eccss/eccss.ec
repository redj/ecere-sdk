public import IMPORT_STATIC "ecere"
public import IMPORT_STATIC "EDA"   // For FieldValue

import "expressions"

// For extending ECCSS with custom identifiers and styling properties
public struct ECCSSEvaluator
{
   subclass(ECCSSEvaluator) evaluatorClass;        // This is effectively adding a virtual function table...

   virtual Class resolve(const CMSSIdentifier identifier, int * fieldID, ExpFlags * flags) { return null; }
   virtual void compute(int fieldID, const CMSSIdentifier identifier, FieldValue value, ExpFlags * flags);
   virtual void evaluateMember(DataMember prop, CMSSExpression exp, const FieldValue parentVal, FieldValue value, ExpFlags * flags);
   virtual void ::applyStyle(void * object, StylesMask mSet, const FieldValue value, int unit);

   // NOTE: These are quite likely to get ridden of with more generic code...
   virtual String ::stringFromMask(StylesMask mask, Class c) { return null; }
   virtual StylesMask ::maskFromString(const String s, Class c) { return 0; }
   virtual Array<Instance> ::accessSubArray(void * obj, StylesMask mask) { return null; }
};

public class CMSSStyleSheet
{
public:
   StylingRuleBlockList list;

   // Returns first rule block intersecting mask and containing name
   StylingRuleBlock findRule(StylesMask mask, const String name)
   {
      if(this && list)
      {
         for(b : list)
         {
            StylingRuleBlock block = b.findRule(mask, name);
            if(block)
               return block;
         }
      }
      return null;
   }

   //NOTE this ignores selectors!
   bool changeStyle(const String id, StylesMask mask, const FieldValue value, bool isNested, Class unitClass)
   {
      bool result = false;
      StylingRuleBlock block = findRule(mask, id);
      if(block)
      {
         CMSSMemberInit mInit = block.styles ? block.styles.findStyle(mask) : null;
         if(mInit)
         {
            delete mInit.initializer;
            mInit.initializer = CMSSInitExp { exp = CMSSExpConstant { constant = value } };
            block.styles.mask |= mask;
            block.mask |= mask;
            result = true;
         }
         // NOTE check outside instead. The issue is the likely need to pass a class, and this complicates matters
         /*else
         {
            ECCSSEvaluator evaluator { };//ECCSSEEvaluator { };
            block.styles = { };
            //block.styles.addStyle(mask, value, evaluator);
         }*/
      }
      return result;
   }
   //NOTE this ignores selectors!
   /*
   bool addStyle(const String id, StylesMask mask, FieldValue value, Class c, ECCSSEvaluator evaluator)
   {
      bool result = false;
      StylingRuleBlock block = findRule(mask, id);
      if(block)
      {
         if(!block.styles) block.styles = { };
         result = block.styles.addStyle(mask, value, c, evaluator);
         if(result) block.mask |= mask;
      }
      return result;
   }*/

   //NOTE this ignores selectors!
   void removeStyle(const String id, StylesMask mask)
   {
      StylingRuleBlock block = findRule(mask, id);
      if(block)
      {
         block.styles.removeStyle(mask);
      }
   }

   CMSSStyleSheet bind(ECCSSEvaluator evaluator, Class stylesClass, const String name)
   {
      CMSSStyleSheet result = null;
      if(this && list)
      {
         for(b : list)
         {
            StylingRuleBlock block = b.bind(evaluator, stylesClass, name);
            if(block)
            {
               if(!result) result = { list = { } };
               result.list.Add(block);
            }
         }
      }
      return result;
   }
   bool resolve(ECCSSEvaluator evaluator, Class stylesClass)
   {
      bool result = false;
      if(this && list)
      {
         for(b : list)
         {
            result = b.resolve(evaluator, stylesClass);
            if(!result) break;
         }
      }
      return result;
   }

   bool write(const String path)
   {
      bool result = false;
      File f = FileOpen(path, write);
      if(f)
      {
         result = writeFile(f);
         delete f;
      }
      return result;
   }

   bool writeFile(File f)
   {
      if(list)
         list.print(f, 0, { skipEmptyBlocks = true });
      return true;
   }

   CMSSStyleSheet ::loadFile(File f)
   {
      StylingRuleBlockList list = null;
      if(f)
      {
         CMSSLexer lexer { };
         lexer.initFile(f);
         list = StylingRuleBlockList::parse(lexer);
         delete lexer;
      }
      return CMSSStyleSheet { list = list ? list : { } };
   }

   CMSSStyleSheet ::load(const String fileName)
   {
      CMSSStyleSheet result = null;
      File f = fileName ? FileOpen(fileName, read) : null;
      if(f)
      {
         result = loadFile(f);
         delete f;
      }
      return result;
   }

   CMSSStyleSheet ::loadString(const String s)
   {
      CMSSStyleSheet result = null;
      if(s)
      {
         TempFile tmp { buffer = (byte *)s, size = strlen(s) };
         result = loadFile(tmp);
         tmp.StealBuffer();
         delete tmp;
      }
      return result;
   }

   CMSSStyleSheet copy()
   {
      CMSSStyleSheet sheet { list = list.copy() };
      return sheet;
   }
}

public class StylesMask : uint64 { bool bitMember:1:63; } // Just to force this to be a bit class...

public class StylesList : CMSSList<CMSSMemberInitList>
{
public:
   StylesMask mask;
   StylesList ::parse(CMSSLexer lexer)
   {
      StylesList list = null;
      while(true)
      {
         CMSSMemberInitList e = CMSSMemberInitList::parse(lexer);
         if(e)
         {
            if(!list) list = StylesList { };
            list.Add(e);
         }
         else
            break;
         lexer.peekToken();
         if(lexer.nextToken.type == '#' || lexer.nextToken.type == '[' ||
            lexer.nextToken.type == '{' || lexer.nextToken.type == '}' || !lexer.nextToken.type)
            break;
      }
      return list;
   }

   CMSSExpression getStyle2(StylesMask msk, Class * uc)
   {
      CMSSExpression result = getStyle(msk);
      while(result && result._class == class(CMSSExpInstance))
      {
         CMSSExpInstance ei = (CMSSExpInstance)result;
         if(uc && ei.instance && ei.instance._class)
         {
            CMSSSpecName sn = (CMSSSpecName)ei.instance._class;
            Class c = sn ? eSystem_FindClass(__thisModule, sn.name) : null;
            if(c && c.type == unitClass && c.base.type == unitClass)
            {
               *uc = c;
               msk = 0;
            }
         }
         else
            result = null;

         if(ei.instance && ei.instance.members)
         {
            for(i : ei.instance.members)
            {
               CMSSInstInitMember member = (CMSSInstInitMember)i;
               CMSSMemberInitList members = member.members;
               CMSSMemberInit mInit = members ? members.findStyle(msk) : null;
               if(mInit)
               {
                  result = mInit.initializer ? ((CMSSInitExp)mInit.initializer).exp : null;
                  break;
               }
            }
         }
      }
      return result;
   }

   CMSSMemberInit findStyle(StylesMask msk)
   {
      // unbound sheet currently doesn't have mask set...
      // if(mask & this.mask)
      {
         for(e : this)
         {
            CMSSMemberInit mInit = e.findStyle(msk);
            if(mInit) return mInit;
         }
      }
      return null;
   }

   void removeStyle(StylesMask msk)
   {
      Iterator<CMSSMemberInitList> it { this };
      it.Next();
      while(it.pointer)
      {
         IteratorPointer next = it.container.GetNext(it.pointer);
         CMSSMemberInitList memberInitList = it.data;
         memberInitList.removeStyle(msk);
         if(memberInitList.GetCount() == 0)
         {
            it.Remove();
            delete memberInitList;
         }
         it.pointer = next;
      }
      mask &= ~msk; // todo: make sure this is ok or write a mask recalculation function?
   }

   CMSSExpression getStyle(StylesMask mask)
   {
      CMSSExpression result = null;
      CMSSMemberInit mInit = findStyle(mask);
      if(mInit)
         result = mInit.initializer ? ((CMSSInitExp)mInit.initializer).exp : null;
      return result;
   }

   void setStyle(StylesMask mask, CMSSExpression exp)
   {
      CMSSMemberInit mInit = findStyle(mask);
      if(!mInit)
         ; // TODO: Create one
      delete mInit.initializer;
      mInit.initializer = CMSSInitExp { exp = exp };
   }

   bool changeStyle(StylesMask msk, const FieldValue value, Class c, ECCSSEvaluator evaluator, bool isNested, Class uc)
   {
      bool result = false;
      bool isTopLevel = true;

      if(this)
      {
         CMSSMemberInit mInit = findStyle(msk);
         CMSSInitExp initExp = null;
         CMSSMemberInitList list = null;
         while(mInit && !initExp)
         {
            initExp = mInit.initializer ? (CMSSInitExp)mInit.initializer : null;
            if(initExp && initExp.exp._class == class(CMSSExpInstance))
            {
               CMSSExpInstance inst = (CMSSExpInstance)initExp.exp;
               CMSSInstantiation instance = inst.instance;
               CMSSInstInitList instInitList = instance.members;
               CMSSSpecName specName = (CMSSSpecName)instance._class;
               Class cuc = specName && specName.name ? eSystem_FindClass(__thisModule, specName.name) : null;
               bool isUnitClass = cuc && cuc.type == unitClass && cuc.base.type == unitClass;

               if(!isUnitClass)
               {
                  // Dealing with sub-instance (and not just a unit value)...
                  initExp = null;
                  isTopLevel = false;
                  isNested = false;    // Force 'isNested' to false if we're aleady modifying the parent instance
                                       // because addStyle() currently does not support handling this for sub-instances
                  if(!instInitList)
                     instance.members = instInitList = { };

                  if(instInitList)
                  {
                     for(i : instInitList)
                     {
                        CMSSInstInitMember member = (CMSSInstInitMember)i;
                        CMSSMemberInitList members = member.members;
                        list = members;
                        mInit = members ? members.findStyle(msk) : null;
                        if(mInit)
                           break;
                     }
                  }
               }
            }
         }

         if(initExp)
         {
            delete initExp.exp;
            initExp.exp = expressionFromValue(value, uc);
            result = true;
         }
         else if(!mInit)
         {
            if(!list)
               Add(list = { });
            result = list.addStyle(msk, value, c, isTopLevel, evaluator, isNested, uc);
         }
         if(result) mask |= msk;
      }
      return result;
   }
}

public class StylingRuleSelector : CMSSNode
{
public:
   CMSSExpression exp;
   StylingRuleSelector ::parse(CMSSLexer lexer)
   {
      StylingRuleSelector selector = null;
      CMSSExpression e;
      if(lexer.peekToken().type == '[')
         lexer.readToken();
      e = CMSSExpression::parse(lexer);
      if(e)
         selector = { exp = e };
      if(lexer.peekToken().type == ']')
         lexer.readToken();
      return selector;
   }

   void print(File out, int indent, CMSSOutputOptions o)
   {
      out.Print("[");
      exp.print(out, indent, o);
      out.Print("]");
   }
   StylingRuleSelector copy()
   {
      StylingRuleSelector s = null;
      if(this)
      {
         s = eInstance_New(_class);
         incref s;
         s.exp = exp.copy();
      }
      return s;
   }
}

public class SelectorList : CMSSList<StylingRuleSelector>
{
public:
   SelectorList ::parse(CMSSLexer lexer)
   {
      SelectorList list = null;
      while(true)
      {
         StylingRuleSelector e = StylingRuleSelector::parse(lexer);
         if(e)
         {
            if(!list) list = SelectorList { };
            list.Add(e);
         }
         else
            break;
         lexer.peekToken();
         if(lexer.nextToken.type == '#' || lexer.nextToken.type == '{' || lexer.nextToken.type == '}' || !lexer.nextToken.type)
            break;
      }
      return list;
   }

   void print(File out, int indent, CMSSOutputOptions o)
   {
      CMSSList::print(out, indent, o);
   }

   void printSep(File out)
   {

   }
}

public class StylingRuleBlockList : CMSSList<StylingRuleBlock>
{
   // TODO: Optimization Maps per re-used attributes of values -> relevant nested rules

public:
   StylingRuleBlockList ::parse(CMSSLexer lexer)
   {
      return (StylingRuleBlockList)CMSSList::parse(class(StylingRuleBlockList), lexer, StylingRuleBlock::parse, 0);
   }
   StylesMask mask;

   void print(File out, int indent, CMSSOutputOptions o)
   {
      CMSSList::print(out, indent, o);
   }

   void printSep(File out)
   {
   }

   StylesMask apply(void * object, StylesMask m, ECCSSEvaluator evaluator, ExpFlags * flg)
   {
      Link it = list.last;
      //Iterator<StylingRuleBlock> it { list };
      while(m && it) //it.Prev())
      {
         StylingRuleBlock block = (StylingRuleBlock)(uint64)it.data;
         StylesMask bm = block.mask & m;
         if(bm)
            m = block.apply(object, m, evaluator, flg, false);
         it = it.prev;
      }
      return m;
   }
}

private Instance createGenericInstance(CMSSExpInstance inst, ECCSSEvaluator evaluator, ExpFlags * flg)
{
   CMSSSpecName specName = inst.instance ? (CMSSSpecName)inst.instance._class : null;
   Class c = specName ? eSystem_FindClass(specName._class.module, specName.name) : inst.destType;
   Instance instance = c && c.structSize ? eInstance_New(c) : null;
   if(instance)
      setGenericInstanceMembers(instance, inst, evaluator, flg);
   return instance;
}

private void setGenericBitMembers(CMSSExpInstance expInst, uint64 * bits, ECCSSEvaluator evaluator, ExpFlags * flg)
{
   if(expInst)
   {
      for(i : expInst.instance.members)
      {
         CMSSInstInitMember member = (CMSSInstInitMember)i;
         for(m : member.members)
         {
            CMSSMemberInit mInit = m;
            if(mInit.initializer._class == class(CMSSInitExp))
            {
               CMSSInitExp initExp = (CMSSInitExp)mInit.initializer;
               CMSSExpression exp = initExp.exp;
               Class destType = exp.destType;
               if(destType)
               {
                  FieldValue val { };
                  ExpFlags flag = exp.compute(val, evaluator, runtime);
                  BitMember member = (BitMember)mInit.dataMember;

                  *bits |= (val.i << member.pos) & member.mask;

                  *flg |= flag;
               }
               else
               {
                  // PrintLn("null destType ?");
               }
            }
         }
      }
   }
}

private void setGenericInstanceMembers(Instance object, CMSSExpInstance expInst, ECCSSEvaluator evaluator, ExpFlags * flg)
{
   if(expInst && expInst.instance)
   {
      for(i : expInst.instance.members)
      {
         CMSSInstInitMember member = (CMSSInstInitMember)i;
         for(m : member.members)
         {
            CMSSMemberInit mInit = m;
            if(mInit.initializer && mInit.initializer._class == class(CMSSInitExp))
            {
               CMSSInitExp initExp = (CMSSInitExp)mInit.initializer;
               CMSSExpression exp = initExp.exp;
               Class destType = exp.destType;
               if(destType)
               {
                  FieldValue val { };
                  ExpFlags flag = exp.compute(val, evaluator, runtime);

                  if(mInit.dataMember && mInit.dataMember.isProperty)
                  {
                     Property prop = (Property)mInit.dataMember;

                     if(destType == class(int) || destType == class(bool) || destType == class(Color) ||
                        ((destType.type == enumClass || destType.type == bitClass) && destType.typeSize == sizeof(int)))
                     {
                        void (* setInt)(void * o, int v) = (void *)prop.Set;
                        setInt(object, val.type.type == integer ? (int)val.i : val.type.type == real ? (int)val.r : 0);
                     }
                     else if(destType == class(int64) ||
                        ((destType.type == enumClass || destType.type == bitClass) && destType.typeSize == sizeof(int64)))
                     {
                        void (* setInt64)(void * o, int64 v) = (void *)prop.Set;
                        setInt64(object, val.type.type == integer ? (int64)val.i : val.type.type == real ? (int64)val.r : 0);
                     }
                     else if(destType == class(double))
                     {
                        void (* setDouble)(void * o, double v) = (void *)prop.Set;
                        setDouble(object, val.type.type == integer ? (double)val.i : val.type.type == real ? val.r : 0);
                     }
                     else if(destType == class(float))
                     {
                        void (* setFloat)(void * o, float v) = (void *)prop.Set;
                        setFloat(object, val.type.type == integer ? (float)val.i : val.type.type == real ? (float)val.r : 0);
                     }
                     else if(destType == class(String))
                     {
                        void (* setString)(void * o, String v) = (void *)prop.Set;
                        setString(object,
                           (val.type.type == text)    ? CopyString(val.s)  :
                           (val.type.type == real)    ? PrintString(val.r) :
                           (val.type.type == integer) ? PrintString(val.i) : null);
                     }
                     else if((destType.type == noHeadClass || destType.type == normalClass) && exp._class == class(CMSSExpInstance))
                     {
                        void (* setInstance)(void * o, void * v) = (void *)prop.Set;
                        setInstance(object,  (Instance)(uintptr)val.i);

                        //if we're freeing these Instances later, is it then the case that
                        //we give CMSSExpInstance this instData member and free it in destructor
                     }
                     else if(destType.type == structClass && exp._class == class(CMSSExpInstance))
                     {
                        void (* setInstance)(void * o, void * v) = (void *)prop.Set;
                        setInstance(object,  (void *)(uintptr)val.i);
                     }
                     else if((destType.type == noHeadClass || destType.type == normalClass) && exp._class == class(CMSSExpArray))
                     {
                        void (* setInstance)(void * o, void * v) = (void *)prop.Set;
                        CMSSExpArray arrayExp = (CMSSExpArray) exp;
                        Array<Instance> array { size = (arrayExp.elements ? arrayExp.elements.GetCount() : 0) };
                        Iterator<CMSSExpression> it { arrayExp.elements };
                        int j = 0;

                        // NOTE: Currently only supporting array of instances...
                        while(it.Next())
                        {
                           CMSSExpression e = it.data;
                           if(e._class == class(CMSSExpInstance))
                           {
                              CMSSExpInstance instExp = (CMSSExpInstance)e;
                              Instance a = instExp.instData;
                              Class c = instExp.expType;
                              if(c && c.type == normalClass)
                                 a._refCount++;

                              array[j] = instExp.instData;
                           }
                           j++;
                        }

                        setInstance(object,  (Instance)(uintptr)array);

                        delete array;
                     }
                     else if(flag.resolved) //!flag.callAgain && !flag.record)  //flag.resolved) //
                     {
                        /*ConsoleFile con { };
                        exp.print(con, 0,0);
                        */
   #ifdef _DEBUG
                        PrintLn("Unexpected!");
   #endif
                     }
                  }
                  else
                  {
                     if(destType == class(int) || destType == class(bool) || destType == class(Color) ||
                        ((destType.type == enumClass || destType.type == bitClass) && destType.typeSize == sizeof(int)))
                        *(int *)((byte *)object + mInit.offset) = val.type.type == integer ? (int)val.i : val.type.type == real ? (int)val.r : 0;
                     else if(destType == class(int64) ||
                        ((destType.type == enumClass || destType.type == bitClass) && destType.typeSize == sizeof(int64)))
                        *(int64 *)((byte *)object + mInit.offset) = val.type.type == integer ? (int64)val.i : val.type.type == real ? (int64)val.r : 0;
                     else if(destType == class(double))
                        *(double *)((byte *)object + mInit.offset) = val.type.type == integer ? (double)val.i : val.type.type == real ? val.r : 0;
                     else if(destType == class(float))
                        *(float *)((byte *)object + mInit.offset) = val.type.type == integer ? (float)val.i : val.type.type == real ? (float)val.r : 0;
                     else if(destType == class(String))
                     {
                        *(String *)((byte *)object + mInit.offset) =
                           (val.type.type == text)    ? CopyString(val.s)  :
                           (val.type.type == real)    ? PrintString(val.r) :
                           (val.type.type == integer) ? PrintString(val.i) : null;
                     }
                     else if((destType.type == noHeadClass || destType.type == normalClass) && exp._class == class(CMSSExpInstance))
                     {
                        // TOFIX: We should probably be deleting existance value here?

                        *(Instance *)((byte *)object + mInit.offset) = (Instance)(uintptr)val.i;
                     }
                     else if(destType.type == structClass && exp._class == class(CMSSExpInstance))
                     {
                        memcpy((byte *)object + mInit.offset, (void *)(uintptr)val.i, destType.structSize);
                     }
                     else if(flag.resolved) //!flag.callAgain && !flag.record)  //flag.resolved) //
                     {
                        /*ConsoleFile con { };
                        exp.print(con, 0,0);
                        */
   #ifdef _DEBUG
                        PrintLn("Unexpected!");
   #endif
                     }
                  }
                  *flg |= flag;
               }
               else
               {
                  // PrintLn("null destType ?");
               }
            }
         }
      }
   }
}

public class StylingRuleBlock : CMSSNode
{
   class_no_expansion;
public:
   StylingRuleBlockList nestedRules;
   SelectorList selectors;
   CMSSIdentifier id;
   StylesList styles;
   StylesMask mask;

   StylingRuleBlock ::parse(CMSSLexer lexer)
   {
      lexer.peekToken();

      if(lexer.nextToken.type == '[' || lexer.nextToken.type == '#' || lexer.nextToken.type == '{')
      {
         StylingRuleBlock block { };

         if(lexer.peekToken().type == '#')
         {
            lexer.readToken();
            if(lexer.peekToken().type == identifier)
               block.id = CMSSIdentifier::parse(lexer);
         }

         if(lexer.peekToken().type == '[')
            block.selectors = SelectorList::parse(lexer);

         if(lexer.peekToken().type == '{')
            lexer.readToken();

         if(lexer.peekToken().type == identifier)
            block.styles = StylesList::parse(lexer);

         lexer.peekToken();
         if(lexer.nextToken.type == '[' || lexer.nextToken.type == '#' || lexer.nextToken.type == '{')
            block.nestedRules = StylingRuleBlockList::parse(lexer);

         if(lexer.peekToken().type == '}')
            lexer.readToken();
         return block;
      }
      return null;
   }

   // Returns first rule block intersecting mask and containing name
   StylingRuleBlock findRule(StylesMask mask, const String name)
   {
      if(id && id.string && name && strcmpi(id.string, name))
         return null;

      if(styles && styles.GetCount())
      {
         for(s : styles)
         {
            for(m : s)
            {
               CMSSMemberInit mInit = m;
               StylesMask sm = mInit.stylesMask;
               if(sm & mask)
                  return this;
            }
         }
      }

      if(nestedRules)
      {
         for(b : nestedRules)
         {
            StylingRuleBlock block = b.findRule(mask, name);
            if(block)
               return b;
         }
      }

      return null;
   }

   private StylingRuleBlock bind(ECCSSEvaluator evaluator, Class stylesClass, const String name)
   {
      StylingRuleBlock result = null;
      bool keep = true;
      SelectorList newSelectors = null;

      // Layer ID filter
      if(id && id.string && name && strcmpi(id.string, name))
         keep = false;

      // Selector expressions filter
      if(keep && selectors)
      {
         // TODO: Per-record flags for selectors?
         for(s : selectors)
         {
            FieldValue value { };
            CMSSExpression e = s.exp.copy();
            ExpFlags flags = e.compute(value, evaluator, preprocessing);
            if(flags.resolved)
            {
               e = simplifyResolved(value, e);
               delete e; // NOTE: viz.sd operations were being deleted when resolved
               if(!value.i)
               {
                  keep = false;
                  break;
               }
            }
            else
            {
               if(!newSelectors) newSelectors = { };
               newSelectors.Add(StylingRuleSelector { exp = e });
            }
         }
         if(!keep) delete newSelectors;
      }

      if(keep)
      {
         StylingRuleBlock block { selectors = newSelectors };
         StylesMask mask = 0;
         if(id) block.id = { string = CopyString(id.string) };
         if(styles)
         {
            StylesList newStyles { };
            for(s : styles)
            {
               CMSSMemberInitList style = s;
               CMSSMemberInitList newStyle { };
               for(m : style)
               {
                  CMSSMemberInit member = m.copy();
                  /*ExpFlags flags = */member.precompute(stylesClass, 0, null, evaluator);  // TODO: Consider these flags
                  newStyle.Add(member);
                  newStyles.mask |= member.stylesMask;
               }
               newStyles.Add(newStyle);
            }
            block.styles = newStyles;
            mask |= newStyles.mask;
         }

         if(nestedRules)
         {
            for(b : nestedRules)
            {
               StylingRuleBlock nb = b.bind(evaluator, stylesClass, name);
               if(nb)
               {
                  if(!block.nestedRules) block.nestedRules = { };
                  block.nestedRules.Add(nb);
                  block.nestedRules.mask |= nb.mask;
               }
            }
            if(block.nestedRules) mask |= block.nestedRules.mask;
         }
         block.mask = mask;
         result = block;
      }
      return result;
   }

   private bool resolve(ECCSSEvaluator evaluator, Class stylesClass)
   {
      bool result = false;
      if(selectors)
      {
         // TODO: Per-record flags for selectors?
         for(s : selectors)
         {
            FieldValue value { };
            CMSSExpression e = s.exp;
            ExpFlags flags = e.compute(value, evaluator, preprocessing);
            if(flags.resolved)
            {
               e = simplifyResolved(value, e);
               s.exp = e;
               //delete e; // NOTE: viz.sd operations were being deleted when resolved
            }
         }
      }

      if(styles)
      {
         for(s : styles)
         {
            CMSSMemberInitList style = s;
            for(m : style)
            {
               CMSSMemberInit member = m;
               // passing stylesClass here just passes irrelevant GeoSymbolizer class, but the others are not yet bound
               member.precompute(stylesClass, 0, null, evaluator);  // TODO: Consider these flags
               styles.mask |= member.stylesMask;
            }
         }
         this.mask |= styles.mask;
      }

      if(nestedRules)
      {
         for(b : nestedRules)
         {
            b.resolve(evaluator, stylesClass);
            nestedRules.mask |= b.mask;
         }
         mask |= nestedRules.mask;
      }
      result = true;

      return result;
   }

   CMSSExpression getStyle(StylesMask mask)
   {
      return styles ? styles.getStyle(mask) : null;
   }

   void setStyle(StylesMask mask, CMSSExpression exp)
   {
      if(!styles) styles = { };
      return styles.setStyle(mask, exp);
   }
   // NOTE: isNested means this is a nested rule, and we want to set top.sub = as opposed to top = { sub = }
   bool changeStyle(StylesMask msk, const FieldValue value, Class c, ECCSSEvaluator evaluator, bool isNested, Class unitClass)
   {
      if(msk)
      {
         if(!styles) styles = { };
         if(styles.changeStyle(msk, value, c, evaluator, isNested, unitClass))
         {
            mask |= msk;
            return true;
         }
      }
      return false;
   }

   void removeStyle(StylesMask msk)
   {
      if(this)
      {
         styles.removeStyle(msk);
      }
   }

   void print(File out, int indent, CMSSOutputOptions o)
   {
      const char * ln = o.dbgOneLiner ? " " : "\n";

      if(o.skipEmptyBlocks &&
         (!styles || !styles.list.first) &&
         (!nestedRules || !nestedRules.list.count))
         return;

      out.Print(ln);
      if(!o.dbgOneLiner) printIndent(indent, out);
      if(id)
      {
         out.Print("#");
         id.print(out, indent, o);
      }

      if(selectors)
         selectors.print(out, indent, o);

      if(id || selectors)
      {
         out.Print(ln);
         if(!o.dbgOneLiner) printIndent(indent, out);
      }
      out.Print("{", ln);
      indent++;

      if(styles)
      {
         Iterator<CMSSMemberInitList> it { styles };
         while(it.Next())
         {
            CMSSMemberInitList list = it.data;

            if(!o.dbgOneLiner) printIndent(indent, out);
            list.print(out, indent, o);
            out.Print(";", ln);
         }
      }
      if(nestedRules)
         nestedRules.print(out, indent, o);

      indent--;
      if(!o.dbgOneLiner) printIndent(indent, out);

      out.Print("}", ln);
   }

   void debugPrintRule(File out, const String name)
   {
      out.Print("   ", name, " @", this ? "" : "0x0", (uintptr)this, ": ");
      if(this) print(out, 32, { dbgOneLiner = true });
      out.PrintLn("");
   }

   ~StylingRuleBlock()
   {
      delete selectors;
      delete id;
      delete styles;
      delete nestedRules;
   }

   StylingRuleBlock copy()
   {
      StylingRuleBlock b = null;

      if(this)
      {
         b = eInstance_New(_class);
         incref b;
         b.mask = mask;
         b.id = (id && id.string) ? { string = CopyString(id.string) } : null;
         if(nestedRules)
         {
            b.nestedRules = { mask = nestedRules.mask };
            for(n : nestedRules)
               b.nestedRules.Add(n.copy());
         }
         if(selectors)
         {
            b.selectors = { };
            for(n : selectors)
               b.selectors.Add(n.copy());
         }
         if(styles)
         {
            b.styles = { mask = styles.mask };
            for(n : styles)
               b.styles.Add(n.copy());
         }
      }
      return b;
   }

   // TOCHECK: Both mask and flags must be returned?
   private /*static*/ StylesMask apply(void * object, StylesMask m, ECCSSEvaluator evaluator, ExpFlags * flg, bool ignoreSelectors)
   {
      ExpFlags flags = 0;
      bool apply = true;

      if(selectors && !ignoreSelectors)
      {
         Link s;
         // TODO: Per-record flags for selectors?
         for(s = selectors.list.first; s; s = s.next)
         {
            StylingRuleSelector sel = (StylingRuleSelector)(uintptr)s.data;
            FieldValue value { };
            CMSSExpression e = sel.exp;
            ExpFlags sFlags = e.compute(value, evaluator, runtime);
            flags |= sFlags;

            if(!sFlags.resolved || !value.i)
               apply = false;
            //callAgain = flags.callAgain;
         }
         *flg |= flags;
      }

      if(apply)
      {
         if(nestedRules)
            m = nestedRules.apply(object, m, evaluator, flg);
         if(m)
         {
            //Iterator<CMSSMemberInitList> itStyle { styles };
            Link itStyle = styles ? styles.list.last : null;
            while(itStyle) //.Prev())
            {
               CMSSMemberInitList initList = (CMSSMemberInitList)(uintptr)itStyle.data;
               //Iterator<CMSSMemberInit> itMember { itStyle.data };
               Link itMember = initList.list.last;
               while(itMember) //.Prev())
               {
                  CMSSMemberInit member = (CMSSMemberInit)(uintptr)itMember.data;
                  CMSSInitExp initExp = member.initializer && member.initializer._class == class(CMSSInitExp) ? (CMSSInitExp)member.initializer : null;
                  CMSSExpression e = initExp.exp;
                  StylesMask sm = member.stylesMask;
                  if(sm & m)
                  {
                     applyStyle(object, sm & m, evaluator, e, flg);
                     m &= ~sm;
                  }
                  itMember = itMember.prev;
               }
               itStyle = itStyle.prev;
            }
         }
      }
      return m;
   }

   private static void ::applyStyle(void * object, StylesMask mSet, ECCSSEvaluator evaluator, CMSSExpression e, ExpFlags * flg)
   {
      CMSSExpInstance inst = e._class == class(CMSSExpInstance) ? (CMSSExpInstance)e : null;
      CMSSExpArray arr = e._class == class(CMSSExpArray) ? (CMSSExpArray)e : null;
      int unit = 0;

      if(inst)
      {
         CMSSSpecName spec = (CMSSSpecName)inst.instance._class;
         String n = spec ? spec.name : null;
         if(n && !strcmpi(n, "Meters"))     // TODO: make this generic
         {
            unit = 1; // meters
            e = null;
            for(i : inst.instance.members)
            {
               CMSSInstInitMember member = (CMSSInstInitMember)i;
               for(m : member.members)
               {
                  CMSSMemberInit mInit = m;
                  if(mInit.initializer._class == class(CMSSInitExp))
                  {
                     CMSSInitExp initExp = (CMSSInitExp)mInit.initializer;
                     e = initExp.exp;
                     if(!e.destType) e.destType = class(double);
                     break;
                  }
               }
               if(e) break;
            }
            inst = null;
         }
         else
            applyInstanceStyle(object, mSet, inst, evaluator, flg);
      }

      if(arr)
      {
         if(evaluator != null)
         {
            // TODO: Do this in a more generic manner
            Array<Instance> array = evaluator.evaluatorClass.accessSubArray(object, mSet);
            if(array)
               for(e : arr.elements; e._class == class(CMSSExpInstance))
                  array.Add(createGenericInstance((CMSSExpInstance)e, evaluator, flg));
         }
      }
      else if(e && !inst)
      {
         FieldValue value { };
         ExpFlags mFlg = e.compute(value, evaluator, runtime);
         Class destType = e.destType;
         Class expType = e.expType;
         if(mFlg.resolved && destType && expType != destType)
         {
            if(destType == class(float) || destType == class(double))
               convertFieldValue(value, real, value);
            else if(destType == class(String))
               convertFieldValue(value, text, value);
            else if(destType == class(int64) || destType == class(int) || destType == class(uint64) || destType == class(uint))
               convertFieldValue(value, integer, value);
         }
         evaluator.evaluatorClass.applyStyle(object, mSet, value, unit);
         *flg |= mFlg;
      }
   }

   private static void ::applyInstanceStyle(void * object, StylesMask mask, CMSSExpInstance inst,
      ECCSSEvaluator evaluator, ExpFlags * flg)
   {
      if(inst)
      {
         for(i : inst.instance.members)
         {
            CMSSInstInitMember member = (CMSSInstInitMember)i;
            for(m : member.members)
            {
               CMSSMemberInit mInit = m;
               if(mInit.initializer._class == class(CMSSInitExp))
               {
                  CMSSInitExp initExp = (CMSSInitExp)mInit.initializer;
                  StylesMask sm = mInit.stylesMask;
                  if(sm & mask)
                  {
                     applyStyle(object, sm & mask, evaluator, initExp.exp, flg);
                     mask &= ~sm;
                  }
               }
            }
         }
      }
   }
};
