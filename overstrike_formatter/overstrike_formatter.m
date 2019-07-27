//
//  main.m
//  overstrike_formatter
//
//  Created by epimorphic on 2019-03-09.
//

#import <Foundation/Foundation.h>
// #import <wchar.h>

static NSString *lastCCS;

#define STYLE_NORMAL 0
#define STYLE_BOLD (1 << 0)
#define STYLE_UNDERLINED (1 << 1)
static unsigned int styleFlag = STYLE_NORMAL, lastStyle = STYLE_NORMAL;

static BOOL backspaceFlag = NO;

void printLastCCSWithFormat() {
    if(styleFlag & STYLE_BOLD)
        printf("\033[1m");
    if(styleFlag & STYLE_UNDERLINED)
        printf("\033[4m");
    printf("%s\033[0m", [lastCCS UTF8String]);
    if(styleFlag != STYLE_NORMAL)
        lastStyle = styleFlag;
    styleFlag = STYLE_NORMAL;
}

void queueAndParse(NSString *currentCCS) {
    
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString *i = [[NSString alloc]
                       initWithData:[[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile]
                       encoding:NSUTF8StringEncoding];
        [i enumerateSubstringsInRange:NSMakeRange(0, [i length])
                              options:NSStringEnumerationByComposedCharacterSequences
                           usingBlock:^(NSString *currentCCS, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                               if(backspaceFlag) {
                                   if([lastCCS compare:currentCCS] == NSOrderedSame) {
                                       // If an underscore is overstruck with itself, we need to decide
                                       // whether to bold it or to underline it. The following resolves the
                                       // amiguity basically how less does it (as far as I can tell),
                                       // exception being that if the previous non-normal styling was both
                                       // bold and underlined, we only bold on the first overstrike.
                                       if([currentCCS compare:@"_"] == NSOrderedSame) {
                                           if(styleFlag & (STYLE_BOLD | STYLE_UNDERLINED)) {
                                               styleFlag |= (STYLE_BOLD | STYLE_UNDERLINED);
                                           }
                                           else if(lastStyle != STYLE_NORMAL) {
                                               if(lastStyle & STYLE_BOLD)
                                                   styleFlag |= STYLE_BOLD;
                                               else
                                                   styleFlag |= STYLE_UNDERLINED;
                                           }
                                           else {
                                               styleFlag |= STYLE_BOLD;
                                           }
                                       }
                                       else {
                                           styleFlag |= STYLE_BOLD;
                                       }
                                   }
                                   else if([currentCCS compare:@"_"] == NSOrderedSame) {
                                       styleFlag |= STYLE_UNDERLINED;
                                   }
                                   else if([lastCCS compare:@"_"] == NSOrderedSame) {
                                       styleFlag = STYLE_UNDERLINED;
                                       lastCCS = currentCCS;
                                   }
                                   else {
                                       // printLastCCSWithFormat();
                                       lastCCS = currentCCS;
                                   }
                                   backspaceFlag = NO;
                               }
                               else {
                                   if([currentCCS compare:@"\b"] == NSOrderedSame) {
                                       backspaceFlag = YES;
                                   }
                                   else {
                                       if(lastCCS != NULL) {
                                           printLastCCSWithFormat();
                                       }
                                       lastCCS = currentCCS;
                                   }
                               }
                           }];
        printLastCCSWithFormat();
        printf("\n");
    }
    
    return 0;
}
