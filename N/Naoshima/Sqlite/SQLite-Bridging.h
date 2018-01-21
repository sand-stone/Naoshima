#ifndef SQLite_Bridging_h
#define SQLite_Bridging_h

@import Foundation;

#import "sqlite3.h"

NS_ASSUME_NONNULL_BEGIN
typedef NSString * _Nullable (^_SQLiteTokenizerNextCallback)(const char *input, int *inputOffset, int *inputLength);
int _SQLiteRegisterTokenizer(sqlite3 *db, const char *module, const char *tokenizer, _Nullable _SQLiteTokenizerNextCallback callback);
NS_ASSUME_NONNULL_END

#endif /* SQLite_Bridging_h */
