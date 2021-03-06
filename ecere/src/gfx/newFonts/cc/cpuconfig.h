#ifndef __CPUCONFIG_H__
#define __CPUCONFIG_H__

#if defined(__LUMIN__)
#define CPU_DISABLE_SSE    1
#endif

#if CPU_DISABLE_SSE && !defined(CPU_ENABLE_SSE)
#define CPU_ENABLE_SSE 0
#endif

/* Automatically generated CPU information header */

#define CPUCONF_CHAR_SIZE (1)
#define CPUCONF_SHORT_SIZE (2)
#define CPUCONF_INT_SIZE (4)
#define CPUCONF_LONG_LONG_SIZE (8)
#define CPUCONF_FLOAT_SIZE (4)
#define CPUCONF_DOUBLE_SIZE (8)
#define CPUCONF_LONG_DOUBLE_SIZE (16)

#define CPUCONF_CHAR_BITS (8)
#define CPUCONF_SHORT_BITS (16)
#define CPUCONF_INT_BITS (32)
#define CPUCONF_LONG_LONG_BITS (64)
#define CPUCONF_FLOAT_BITS (32)
#define CPUCONF_DOUBLE_BITS (64)
#define CPUCONF_LONG_DOUBLE_BITS (128)

#define CPUCONF_CHAR_SIZESHIFT (0)
#define CPUCONF_SHORT_SIZESHIFT (1)
#define CPUCONF_INT_SIZESHIFT (2)
#define CPUCONF_LONG_LONG_SIZESHIFT (3)

#define CPUCONF_FLOAT_SIZESHIFT (2)
#define CPUCONF_DOUBLE_SIZESHIFT (3)
#define CPUCONF_LONG_DOUBLE_SIZESHIFT (4)

#define CPUCONF_CHAR_BITSHIFT (3)
#define CPUCONF_SHORT_BITSHIFT (4)
#define CPUCONF_INT_BITSHIFT (5)
#define CPUCONF_LONG_LONG_BITSHIFT (6)
#define CPUCONF_FLOAT_BITSHIFT (5)
#define CPUCONF_DOUBLE_BITSHIFT (6)
#define CPUCONF_LONG_DOUBLE_BITSHIFT (7)

#if defined(__BYTE_ORDER) && __BYTE_ORDER == __BIG_ENDIAN || \
    defined(__BIG_ENDIAN__) || \
    defined(__ARMEB__) || \
    defined(__THUMBEB__) || \
    defined(__AARCH64EB__) || \
    defined(_MIBSEB) || defined(__MIBSEB) || defined(__MIBSEB__)
#define CPUCONF_BIG_ENDIAN
#elif defined(__BYTE_ORDER) && __BYTE_ORDER == __LITTLE_ENDIAN || \
    defined(__LITTLE_ENDIAN__) || \
    defined(__ARMEL__) || \
    defined(__THUMBEL__) || \
    defined(__AARCH64EL__) || \
    defined(_MIPSEL) || defined(__MIPSEL) || defined(__MIPSEL__)
#define CPUCONF_LITTLE_ENDIAN
#else
   #define CPUCONF_LITTLE_ENDIAN
   //#error "Unknown endianness"
#endif

#if (defined(__WORDSIZE) && __WORDSIZE == 8) || defined(__x86_64__) || defined(_M_X64) || defined(_WIN64) || defined(__LP64__) || defined(__LLP64__)

#if defined(__x86_64__) || defined(_M_X64)
   #define CPUCONF_ARCH_AMD64
#endif

   #define CPUCONF_INTPTR_SIZE (8)
   #define CPUCONF_POINTER_SIZE (8)
   #define CPUCONF_INTPTR_BITS (64)
   #define CPUCONF_POINTER_BITS (64)
   #define CPUCONF_INTPTR_SIZESHIFT (3)
   #define CPUCONF_POINTER_SIZESHIFT (3)
   #define CPUCONF_INTPTR_BITSHIFT (6)
   #define CPUCONF_POINTER_BITSHIFT (6)

#if defined(__WIN32__)
   #define CPUCONF_LONG_SIZE (4)
#else
   #define CPUCONF_LONG_SIZE (8)
#endif
   #define CPUCONF_LONG_BITSHIFT ((sizeof(long) == 4) ? 5 : 6)
   #define CPUCONF_LONG_SIZESHIFT ((sizeof(long) == 4) ? 2 : 3)
   #define CPUCONF_LONG_BITS (sizeof(long) * 8)

   #define CPUCONF_WORD_SIZE (64)

#else

#if !defined(__EMSCRIPTEN__) && (defined(__i386) || defined(_M_IX86))
   #define CPUCONF_ARCH_IA32
#endif

   #define CPUCONF_INTPTR_SIZE (4)
   #define CPUCONF_POINTER_SIZE (4)
   #define CPUCONF_INTPTR_BITS (32)
   #define CPUCONF_POINTER_BITS (32)
   #define CPUCONF_INTPTR_SIZESHIFT (2)
   #define CPUCONF_POINTER_SIZESHIFT (2)
   #define CPUCONF_INTPTR_BITSHIFT (5)
   #define CPUCONF_POINTER_BITSHIFT (5)

   #define CPUCONF_LONG_SIZE (4)
   #define CPUCONF_LONG_BITSHIFT (5)
   #define CPUCONF_LONG_SIZESHIFT (2)
   #define CPUCONF_LONG_BITS (32)

   #define CPUCONF_WORD_SIZE (32)

#endif
#define CPUCONF_VENDOR_INTEL

#define CPUCONF_IDENTIFIER "Intel(R) Core(TM) i7-2600K CPU @ 3.40GHz"
//#define CPUCONF_CLASS_COREI7-AVX2
#define CPUCONF_SOCKET_LOGICAL_CORES (16)
#define CPUCONF_SOCKET_PHYSICAL_CORES (8)
#define CPUCONF_TOTAL_CORE_COUNT (8)
#define CPUCONF_SYSTEM_MEMORY (17072009216LL)

#define CPUCONF_CACHE_LINE_SIZE (64)
#define CPUCONF_CACHE_L1CODE_SIZE (32768)
#define CPUCONF_CACHE_L1CODE_LINE (64)
#define CPUCONF_CACHE_L1CODE_ASSOCIATIVITY (8)
#define CPUCONF_CACHE_L1CODE_SHARED (2)
#define CPUCONF_CACHE_L1DATA_SIZE (32768)
#define CPUCONF_CACHE_L1DATA_LINE (64)
#define CPUCONF_CACHE_L1DATA_ASSOCIATIVITY (8)
#define CPUCONF_CACHE_L1DATA_SHARED (2)
#define CPUCONF_CACHE_L1_UNIFIED_FLAG (0)
#define CPUCONF_CACHE_L2_SIZE (262144)
#define CPUCONF_CACHE_L2_LINE (64)
#define CPUCONF_CACHE_L2_ASSOCIATIVITY (8)
#define CPUCONF_CACHE_L2_SHARED (2)
#define CPUCONF_CACHE_L3_SIZE (8388608)
#define CPUCONF_CACHE_L3_LINE (64)
#define CPUCONF_CACHE_L3_ASSOCIATIVITY (16)
#define CPUCONF_CACHE_L3_SHARED (16)
#define CPUCONF_CAP_GPREGS (16)
#define CPUCONF_CAP_FPREGS (16)

#define CPUCONF_CAP_CMOV
#define CPUCONF_CAP_CLFLUSH
#define CPUCONF_CAP_TSC
#define CPUCONF_CAP_MMX
#define CPUCONF_CAP_SSE
#define CPUCONF_CAP_SSE2
#define CPUCONF_CAP_SSE3
#define CPUCONF_CAP_SSSE3
#define CPUCONF_CAP_SSE4_1
#define CPUCONF_CAP_SSE4_2
#define CPUCONF_CAP_AVX
#define CPUCONF_CAP_AVX2
#define CPUCONF_CAP_AES
#define CPUCONF_CAP_PCLMUL
#define CPUCONF_CAP_CMPXCHG16B
#define CPUCONF_CAP_MOVBE
#define CPUCONF_CAP_RDTSCP
#define CPUCONF_CAP_CONSTANTTSC
#define CPUCONF_CAP_HYPERTHREADING
#define CPUCONF_CAP_MWAIT
#define CPUCONF_CAP_THERMALSENSOR
#define CPUCONF_CAP_CLOCKMODULATION

#endif
