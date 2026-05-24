# sign_pdf_redpdf

When you build with flutter build appbundle --obfuscate --split-debug-info=build/symbols, the build will produce:

A smaller AAB (R8 strips unused code & resources)
A mapping.txt at android/app/build/outputs/mapping/release/mapping.txt — upload this to Play Console under App Bundle Explorer → Downloads → Deobfuscation file to resolve the warning
Build command
flutter build appbundle --obfuscate --split-debug-info=build/symbols
Then upload mapping.txt alongside your AAB to Play Console.

deobfuscation file associated with this App Bundle. If you use obfuscated code (R8/proguard), uploading a deobfuscation file will make crashes and ANRs easier to analyse and debug. Using R8/proguard can help reduce app size