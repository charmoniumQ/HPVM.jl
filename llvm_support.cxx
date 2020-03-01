#include <llvm/IR/Value.h>
#include <llvm/ADT/StringRef.h>

char* string_ref_to_string(llvm::StringRef sr) {
	auto str = new char[sr.size() + 1];
	std::copy(sr.begin(), sr.end(), str);
	str[sr.size()] = '\0';
	return str;
}

extern "C" const char* value__get_name(llvm::Value* value) {
	return string_ref_to_string(value->getName());
}
