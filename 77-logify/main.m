//
//  main.m
//  77-logify
//
//  Created by 于传峰 on 2017/1/1.
//  Copyright © 2017年 于传峰. All rights reserved.
//

#import <Foundation/Foundation.h>


#define LINE 1024
static NSString* _classHookText;
static NSString* _methodText;

static NSString* _className;

char *ReadData(FILE *fp, char *buf)
{
    return fgets(buf, LINE, fp);//读取一行到buf
}
void someprocess(char *buf)
{
    NSMutableArray* _types = [[NSMutableArray alloc] init];
    NSMutableArray* _names = [[NSMutableArray alloc] init];
    NSString* text = [NSString stringWithUTF8String:buf];
    NSInteger argN = 0;
    
    if ([text hasPrefix:@"@interface"])
    {
        NSRegularExpression* classRegular = [[NSRegularExpression alloc] initWithPattern:@"@interface\\s*\\w*?\\s*\\:" options:0 error:nil];
        NSTextCheckingResult* result = [classRegular firstMatchInString:text options:0 range:NSMakeRange(0, text.length)];
        _className = [text substringWithRange:result.range];
        _className = [_className stringByReplacingOccurrencesOfString:@"@interface" withString:@""];
        _className = [_className stringByReplacingOccurrencesOfString:@":" withString:@""];
        _className = [_className stringByReplacingOccurrencesOfString:@" " withString:@""];
//        NSLog(@"====%@\n-----%@",text, _className);
    }else
    if ([text hasPrefix:@"-"] || [text hasPrefix:@"+"])
    {
        
        NSString* namePattern;
        if (![text containsString:@":"])
        {
            namePattern = @"\\)\\w*?\\;";
        }else{
            namePattern = @"\\)\\w*?\\:|\\ \\w*?\\:";
            argN = [text componentsSeparatedByString:@":"].count - 1;
        }
//        NSLog(@"[%zd]%@", argN, text);
        NSRegularExpression* nameRegular = [[NSRegularExpression alloc] initWithPattern:namePattern options:0 error:nil];
        NSArray* nameTextArray = [nameRegular matchesInString:text options:0 range:NSMakeRange(0, text.length)];
        for (NSTextCheckingResult* result in nameTextArray) {
            NSString* name = [text substringWithRange:result.range];
            name = [name substringWithRange:NSMakeRange(1, name.length-2)];
            [_names addObject:name];
//            NSLog(@"====%@", name);
        }
        
        NSString* typePattern = @"\\(.*?\\)";
        NSRegularExpression* typeRegular = [[NSRegularExpression alloc] initWithPattern:typePattern options:0 error:nil];
        NSArray* typeTextArray = [typeRegular matchesInString:text options:0 range:NSMakeRange(0, text.length)];
        for (NSTextCheckingResult* result in typeTextArray) {
            NSString* typeName = [text substringWithRange:result.range];
            typeName = [typeName substringWithRange:NSMakeRange(1, typeName.length-2)];
            if ([typeName containsString:@" "])
            {
                typeName = @"id";
            }
            [_types addObject:typeName];
        }
        
//        NSLog(@"%@====%@", _types, _names);
        
    }
    
    
    if (_types.count > 0 && _names.count > 0)
    {
        NSString* methodStr = @"", *superStr = @"", *logStr = @"";
        NSString* hookClassStr = @"";
        for ( int i = 0; i < _types.count; i++ )
        {
            if (i == 0)
            {
                methodStr = [NSString stringWithFormat:@"CHMethod(%zd, %@, %@, %@,", argN, _types[i], _className, _names[i]];
                if (![_types[i] isEqualToString:@"void"])
                {
                    superStr = [superStr stringByAppendingString:@"return "];
                }
                superStr = [NSString stringWithFormat:@"%@CHSuper(%zd, %@, %@,", superStr, argN, _className, _names[i]];
                logStr = [NSString stringWithFormat:@"NSLog(@\"%@[%@  %@:", [text substringToIndex:1], _className, _names[i]];
                hookClassStr = [NSString stringWithFormat:@"\tCHClassHook(%zd, %@, %@,", argN, _className, _names[i]];
            }else{
                methodStr = [NSString stringWithFormat:@"%@ %@, arg%zd,", methodStr, _types[i], i];
                superStr = [NSString stringWithFormat:@"%@ arg%zd,", superStr, i];

                if (i < _names.count)
                {
                    methodStr = [NSString stringWithFormat:@"%@ %@,", methodStr, _names[i]];
                    superStr = [NSString stringWithFormat:@"%@ %@,", superStr, _names[i]];
                    logStr = [NSString stringWithFormat:@"%@ %@:", logStr, _names[i]];
                    hookClassStr = [NSString stringWithFormat:@"%@ %@,", hookClassStr, _names[i]];
                }
            }
        }
        methodStr = [methodStr substringToIndex:methodStr.length-1];
        methodStr = [methodStr stringByAppendingString:@") {\n\t"];
        
        superStr = [superStr substringToIndex:superStr.length-1];
        superStr = [superStr stringByAppendingString:@");\n\t"];
        
        if (_types.count == 1)
        {
            logStr = [logStr substringToIndex:logStr.length-1];
        }
        logStr = [logStr stringByAppendingString:@"]\");"];
        
        methodStr = [NSString stringWithFormat:@"%@%@%@", methodStr, superStr, logStr];

        methodStr = [methodStr stringByAppendingString:@"\n}\n\n"];

//        NSLog(@"==%@",methodStr);
        _methodText = [_methodText stringByAppendingString:methodStr];
        

        hookClassStr = [hookClassStr substringToIndex:hookClassStr.length-1];
        hookClassStr = [hookClassStr stringByAppendingString:@");\n"];
//        NSLog(@"==%@",hookClassStr);
        _classHookText = [_classHookText stringByAppendingString:hookClassStr];
    }
}

// CHClassHook(2, WCRedEnvelopesLogicMgr, OnWCToHongbaoCommonResponse, Request);

/*
 CHMethod(2,  void, WCRedEnvelopesLogicMgr, OnWCToHongbaoCommonResponse, HongBaoRes*, arg1, Request, HongBaoReq*, arg2){
 CHSuper(2, WCRedEnvelopesLogicMgr, OnWCToHongbaoCommonResponse,  arg1, Request,  arg2);
 NSLog(@"OnWCToHongbaoCommonResponse >>> \n arg1:%@ \n arg2:%@", arg1, arg2);
 }
 */

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        _classHookText = @"";
        _methodText = @"";
        
        FILE *fp;
        char* fileName = argv[1];
        char *buf, *p;

        if ((fp=fopen(fileName, "r"))==NULL) {
            printf("open file error!!\n");
            exit(2);
        }
        buf=(char*)malloc(LINE*sizeof(char));
        while(1) {
            p = ReadData(fp, buf);//每次调用文件指针fp会自动后移一行
            if(!p)//文件读取结束则跳出循环
                break;
            someprocess(buf);
        }
        fclose(fp);
        
        
        NSString* headStr = @"\n#import <Foundation/Foundation.h>\n#import \"CaptainHook/CaptainHook.h\"";
        headStr =  [headStr stringByAppendingString:@"\n\n"];
        headStr = [headStr stringByAppendingString:[NSString stringWithFormat:@"CHDeclareClass(%@);", _className]];
        headStr =  [headStr stringByAppendingString:@"\n\n"];

        
        NSString* funStr = @"__attribute__((constructor)) static void entry() {\n";
        funStr = [funStr stringByAppendingString:[NSString stringWithFormat:@"\tCHLoadLateClass(%@);", _className]];
        funStr =  [funStr stringByAppendingString:@"\n\n"];
        funStr =  [funStr stringByAppendingString:_classHookText];
        funStr =  [funStr stringByAppendingString:@"\n}"];
        
        NSString* text = [NSString stringWithFormat:@"%@%@%@", headStr, _methodText, funStr];
        
        if (argv[2] != NULL)
        {
            NSError* error;
            [text writeToFile:[NSString stringWithUTF8String:argv[2]] atomically:YES encoding:NSUTF8StringEncoding error:&error];
            if (error != NULL)
            {
                NSLog(@"ERROR!!!\n%@", error);
                exit(2);
            }
        }else{
            NSLog(@"%@", text);
        }
    }
    return 0;
}
/*
 __attribute__((constructor)) static void entry()
 {
 CHLoadLateClass(CMessageMgr);
 CHLoadLateClass(CMessageWrap);
 
 CHLoadLateClass(WCRedEnvelopesLogicMgr);
 CHLoadLateClass(WCRedEnvelopesReceiveControlLogic);
 
 //    CHClassHook(2, CMessageMgr, AsyncOnAddMsg, MsgWrap);
 CHClassHook(2, WCRedEnvelopesLogicMgr, OnWCToHongbaoCommonResponse, Request);
 CHClassHook(2, WCRedEnvelopesReceiveControlLogic, OnQueryRedEnvelopesDetailRequest, Error);
 }
 */
