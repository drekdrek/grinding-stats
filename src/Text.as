// this is a hack to make the text functions work on turbo and mp4
// the renaming of these functions are done in TMNEXT but not MP4 OR TURBO yet
#if TURBO || MP4
namespace Text {
string StripFormatCodes(const string &in text) {
	return StripFormatCodes(text);
}
string OpenplanetFormatCodes(const string &in text) {
	return ColoredString(text);
}
} // namespace Text
#endif
