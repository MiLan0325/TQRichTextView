//
//  TQRichTextView.m
//  TQRichTextViewDemo
//
//  Created by fuqiang on 13-9-12.
//  Copyright (c) 2013年 fuqiang. All rights reserved.
//

#import "TQRichTextView.h"
#import <CoreText/CoreText.h>
#import "TQRichTextEmojiRun.h"

@implementation TQRichTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _text = @"";
        _font = [UIFont systemFontOfSize:12.0];
        _textColor = [UIColor blackColor];
        _lineSpacing = 1.0;
        //
        _richTextRunsArray = [[NSMutableArray alloc] init];
        _textAnalyzed = [self analyzeText:_text];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    //要绘制的文本
    NSMutableAttributedString* attString = [[NSMutableAttributedString alloc] initWithString:self.textAnalyzed];

    //设置字体
    CTFontRef aFont = CTFontCreateWithName((__bridge CFStringRef)self.font.fontName, self.font.pointSize, NULL);
    [attString addAttribute:(NSString*)kCTFontAttributeName value:(__bridge id)aFont range:NSMakeRange(0,attString.length)];
    CFRelease(aFont);
    
    //设置颜色
    [attString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)self.textColor.CGColor range:NSMakeRange(0,attString.length)];
    
    //文本处理
    for (TQRichTextBaseRun *textRun in self.richTextRunsArray)
    {
        [textRun replaceTextWithAttributedString:attString];
    }

    //绘图上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //修正坐标系
    CGAffineTransform textTran = CGAffineTransformIdentity;
    textTran = CGAffineTransformMakeTranslation(0.0, self.bounds.size.height);
    textTran = CGAffineTransformScale(textTran, 1.0, -1.0);
    CGContextConcatCTM(context, textTran);

    //绘制
    int lineCount = 0;
    CFRange lineRange = CFRangeMake(0,0);
    CTTypesetterRef typeSetter = CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attString);
    float drawLineX = 0;
    float drawLineY = self.bounds.origin.y + self.bounds.size.height - self.font.ascender;
    
    BOOL drawFlag = YES;
    
    while(drawFlag)
    {
        CFIndex testLineLength = CTTypesetterSuggestLineBreak(typeSetter,lineRange.location,self.bounds.size.width);
check:  lineRange = CFRangeMake(lineRange.location,testLineLength);
        CTLineRef line = CTTypesetterCreateLine(typeSetter,lineRange);
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        
        //边界检查
        CTRunRef lastRun = CFArrayGetValueAtIndex(runs, CFArrayGetCount(runs) - 1);
        CGFloat lastRunAscent;
        CGFloat laseRunDescent;
        CGFloat lastRunWidth  = CTRunGetTypographicBounds(lastRun, CFRangeMake(0,0), &lastRunAscent, &laseRunDescent, NULL);
        CGFloat lastRunPointX = drawLineX + CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(lastRun).location, NULL);
        
        if ((lastRunWidth + lastRunPointX) > self.bounds.size.width)
        {
            testLineLength--;
            CFRelease(line);
goto check;
        }
        
        //--
        drawLineX = CTLineGetPenOffsetForFlush(line,0,self.bounds.size.width);
        
        CGContextSetTextPosition(context,drawLineX,drawLineY);
        
        CTLineDraw(line,context);
        
        //绘制run
        for (int i = 0; i < CFArrayGetCount(runs); i++)
        {
            CTRunRef run = CFArrayGetValueAtIndex(runs, i);
            NSDictionary* attributes = (__bridge NSDictionary*)CTRunGetAttributes(run);
            
            TQRichTextBaseRun *textRun = [attributes objectForKey:@"TQRichTextAttribute"];
            
            if (textRun)
            {
                CGFloat runAscent,runDescent;
                CGFloat runWidth  = CTRunGetTypographicBounds(run, CFRangeMake(0,0), &runAscent, &runDescent, NULL);
                CGFloat runHeight = runAscent + (-runDescent);
                CGFloat runPointX = drawLineX + CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
                CGFloat runPointY = drawLineY - (-runDescent);
                
                CGRect runRect = CGRectMake(runPointX, runPointY, runWidth, runHeight);
                [textRun drawRunWithRect:runRect];
            }
        }
        
        CFRelease(line);
        
        if(lineRange.location + lineRange.length >= attString.length)
        {
            drawFlag = NO;
        }

        lineCount++;
        
        drawLineY -= self.font.ascender + (- self.font.descender) + self.lineSpacing;
        
        lineRange.location += lineRange.length;
    }
    
    CFRelease(typeSetter);
}

#pragma mark - Set
- (void)setText:(NSString *)text
{
    _text = text;
    _textAnalyzed = [self analyzeText:_text];
}

#pragma mark - analyzeText
//-- 解析文本内容
- (NSString *)analyzeText:(NSString *)string
{
    NSString *result = @"";
    
    NSMutableArray *array = self.richTextRunsArray;
    
    result = [TQRichTextEmojiRun analyzeText:string runsArray:&array];
    
    [self.richTextRunsArray makeObjectsPerformSelector:@selector(setOriginalFont:) withObject:self.font];
    
    return result;
}


@end














