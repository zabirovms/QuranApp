# 🔒 SECURE PRODUCTION SETUP GUIDE

## ⚠️ CRITICAL SECURITY NOTICE

**NEVER commit production keystores or passwords to version control!**

This guide shows you how to set up production builds securely without exposing sensitive data.

---

## 🛡️ SECURE PRODUCTION SETUP

### **Step 1: Create Production Keystore (LOCALLY ONLY)**

```bash
# Run this command in your project directory
keytool -genkey -v -keystore android/app/quran-app-release-key.keystore -alias quran-app-key -keyalg RSA -keysize 2048 -validity 10000
```

**Important:** Choose strong passwords and remember them!

### **Step 2: Create Secure Configuration File**

Create `android/app/key.properties` (this file is already in .gitignore):

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=quran-app-key
storeFile=quran-app-release-key.keystore
```

### **Step 3: Update build.gradle for Secure Configuration**

The `android/app/build.gradle` file should look like this:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... other configurations

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled false
            shrinkResources false
        }
    }
}
```

### **Step 4: Build Production Files**

```bash
# Clean and build
flutter clean
flutter pub get
flutter build apk --release
flutter build appbundle --release
```

---

## 🔐 SECURITY BEST PRACTICES

### **✅ DO:**
- Keep keystore files local only
- Use strong passwords (12+ characters)
- Store passwords securely (password manager)
- Use environment variables for CI/CD
- Regularly backup keystore files securely

### **❌ NEVER:**
- Commit keystore files to git
- Share keystore files via email/chat
- Use weak passwords
- Store passwords in code
- Upload keystore to cloud storage

---

## 🚨 IF YOU ACCIDENTALLY COMMITTED SENSITIVE DATA

### **Immediate Actions:**
1. **Remove from git history** (already done)
2. **Change all passwords** immediately
3. **Generate new keystore** with new passwords
4. **Revoke old certificates** if possible
5. **Monitor for suspicious activity**

### **Recovery Steps:**
1. Create new keystore with different passwords
2. Update all configuration files
3. Test new builds thoroughly
4. Deploy with new signing

---

## 📱 PRODUCTION BUILD COMMANDS

### **Generate Production APK:**
```bash
flutter build apk --release
```

### **Generate Production AAB:**
```bash
flutter build appbundle --release
```

### **Output Locations:**
- **APK:** `build/app/outputs/apk/release/app-release.apk`
- **AAB:** `build/app/outputs/bundle/release/app-release.aab`

---

## 🔍 VERIFICATION CHECKLIST

Before pushing to GitHub, verify:
- [ ] No keystore files in git status
- [ ] No passwords in build.gradle
- [ ] key.properties is in .gitignore
- [ ] Production builds work locally
- [ ] All sensitive data removed from history

---

## 📞 EMERGENCY CONTACTS

If you suspect your keystore is compromised:
1. **Immediately** generate new keystore
2. **Contact** Google Play Console support
3. **Revoke** old certificates
4. **Monitor** app for unauthorized updates

---

**Remember: Security is everyone's responsibility!** 🛡️
