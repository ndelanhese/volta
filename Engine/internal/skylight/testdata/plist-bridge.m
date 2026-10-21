#import <Foundation/Foundation.h>
#include "plist.h"
#include <stdio.h>
#include <string.h>

int main(int argc, const char **argv) {
    @autoreleasepool {
        NSMutableArray *windows = [NSMutableArray array];
        for (int i = 0; i < 200; i++) {
            [windows addObject:@{
                @"kCGWindowNumber": @(200 + i), @"kCGWindowOwnerPID": @43,
                @"kCGWindowOwnerName": @"Fixture", @"kCGWindowName": [NSString stringWithFormat:@"Janela %d – 文档 🪟", i],
                @"kCGWindowLayer": @0, @"kCGWindowAlpha": @0.75,
                @"kCGWindowBounds": @{@"X": @(-100.25 + i), @"Y": @12.5, @"Width": @800.0, @"Height": @600.0}
            }];
        }
        NSDictionary *root = @{
            @"windows": windows,
            @"displays": @[
                @{@"Display Identifier": @"display-A", @"Current Space": @{@"ManagedSpaceID": @9007199254740993ULL, @"uuid": @"desk-A", @"type": @0}, @"Spaces": @[@{@"ManagedSpaceID": @9007199254740993ULL, @"uuid": @"desk-A", @"type": @0}, @{@"id64": @7, @"uuid": @"desk-B", @"type": @0}]},
                @{@"Display Identifier": @"display-B", @"Current Space": @{@"ManagedSpaceID": @13, @"uuid": @"desk-C", @"type": @0}, @"Spaces": @[@{@"ManagedSpaceID": @13, @"uuid": @"desk-C", @"type": @0}]}
            ],
            @"spaces": @[@9007199254740993ULL, @7],
            @"titles": @[@{@"id": @200, @"title": @""}], @"empty": @[]
        };
        CFDataRef data = argc > 1 && strcmp(argv[1], "xml") == 0
            ? CFPropertyListCreateData(NULL, (__bridge CFTypeRef)root, kCFPropertyListXMLFormat_v1_0, 0, NULL)
            : sk_plist((__bridge CFTypeRef)root);
        if (!data) return 1;
        size_t count = (size_t)CFDataGetLength(data);
        size_t written = fwrite(CFDataGetBytePtr(data), 1, count, stdout);
        CFRelease(data);
        return written == count ? 0 : 2;
    }
}
