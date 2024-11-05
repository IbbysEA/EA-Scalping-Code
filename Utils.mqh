#ifndef __UTILS_MQH__
#define __UTILS_MQH__

string SanitizeForSQL(string text) {
    StringReplace(text, "'", "''");
    return text;
}

#endif // __UTILS_MQH__
