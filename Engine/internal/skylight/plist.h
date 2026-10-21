#ifndef VOLTA_PLIST_H
#define VOLTA_PLIST_H
#include <CoreFoundation/CoreFoundation.h>

// One wire representation for native window, desktop, and title observations.
static inline CFDataRef sk_plist(CFTypeRef obj) {
    if (!obj) return NULL;
    return CFPropertyListCreateData(NULL, obj, kCFPropertyListBinaryFormat_v1_0, 0, NULL);
}
#endif
