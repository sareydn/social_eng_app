## 🧩 Troubleshooting

### Common Errors and Solutions

#### 1. **API Key Issues**
**Error**: "OpenAI API hatası: 401 - Unauthorized"
**Solution**: 
- Verify your OpenAI API key is correct
- Check if your API key has sufficient credits
- Ensure the API key has access to GPT-3.5-turbo and Whisper

#### 2. **File Loading Errors**
**Error**: "Dosya seçilirken hata oluştu"
**Solution**:
- Ensure file format is supported (PDF, DOCX, or audio)
- Check file size (recommended < 25MB)
- Verify file is not corrupted

#### 3. **Audio Transcription Failures**
**Error**: "Ses dosyası metne dönüştürülemedi"
**Solution**:
- Check audio file format compatibility
- Ensure audio quality is clear
- Verify internet connection for API calls

#### 4. **Flutter Build Issues**
**Error**: "flutter pub get" fails
**Solution**:
- Update Flutter SDK to latest version
- Clear Flutter cache: `flutter clean`
- Delete pubspec.lock and run `flutter pub get` again

#### 5. **Platform-Specific Issues**
**Android**: 
- Enable developer options and USB debugging
- Install Android SDK platform tools

**iOS**: 
- Install Xcode command line tools
- Accept developer certificates

**Web**: 
- Use Chrome or Firefox for best compatibility
- Enable microphone permissions for audio features

### Performance Optimization
- **Large Files**: Break down large documents into smaller sections
- **Network Issues**: Ensure stable internet connection for API calls
- **Memory Usage**: Close other applications when processing large files

## 🤝 Acknowledgments

### Course Information
**Course Name**: CSE 473 Network and information security
**Instructor**: Salih  Sarp
**Institution**: [Insert Institution Name Here]
**Semester**: [Insert Semester/Year Here]

### Collaborators
- **Project Lead**: [Your Name]
- **Development Team**: Sare Nur Aydın, Emirhan ŞAL

### Technologies Used
- **Flutter**: Cross-platform development framework
- **OpenAI API**: AI-powered text and audio analysis
- **Syncfusion**: PDF processing capabilities
- **File Picker**: File selection functionality

---

**Note**: This application is designed for educational and protective purposes. It helps identify potential social engineering attempts but should not be considered a replacement for professional security advice.

**Version**: 1.0.0 | 
=======
# social_eng_app
>>>>>>> e3fdd7247b43cde7eec9ba39ed7c0032598cae34
