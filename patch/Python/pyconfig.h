#if TARGET_IPHONE_SIMULATOR
#include "pyconfig-simulator.h"
#elif TARGET_CPU_ARM64
#include "pyconfig-arm64.h"
#else
#include "pyconfig-armv7.h"
#endif