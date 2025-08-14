# Android Location Authorization Troubleshooting Guide

## 🔧 **Common Issues & Solutions**

### **1. Android Emulator Location Issues**

#### **Problem**: Location permission granted but no location data received
**Solution**:
```bash
# Enable location services in emulator
adb shell settings put secure location_providers_allowed +gps
adb shell settings put secure location_providers_allowed +network

# Send mock location data
adb shell am broadcast -a android.location.GPS_ENABLED_CHANGE --ez enabled true
```

**Emulator Settings**:
- Open **Extended Controls** → **Location**
- Set location to a real address (e.g., "1600 Amphitheatre Parkway, Mountain View, CA")
- Enable **GPS** and **Save location**

### **2. Android 13+ Permission Issues**

#### **Problem**: Notification permission affects location services
**Solution**: The app now handles this automatically, but you can manually check:
```bash
# Check notification permission status
adb shell dumpsys package com.roadtrip.copilot | grep POST_NOTIFICATIONS

# Grant notification permission manually
adb shell pm grant com.roadtrip.copilot android.permission.POST_NOTIFICATIONS
```

### **3. Background Location Permission**

#### **Problem**: Background location not working properly
**Solution**:
1. **Grant "Allow all the time"** when prompted
2. **Check battery optimization**:
   - Settings → Apps → Roadtrip-Copilot → Battery → Don't optimize

**Manual Grant (for testing)**:
```bash
# Grant background location permission
adb shell pm grant com.roadtrip.copilot android.permission.ACCESS_BACKGROUND_LOCATION
```

### **4. Device-Specific Issues**

#### **Samsung Devices**:
- Enable **Precise Location** in app permissions
- Disable **Adaptive Battery** for the app
- Allow app to run in background

#### **OnePlus Devices**:
- Disable **Battery Optimization**
- Enable **Auto-start** for the app
- Allow **Background App Refresh**

#### **Xiaomi (MIUI)**:
- Disable **MIUI Optimization**
- Enable **Autostart** in Security app
- Set battery plan to **No restrictions**

### **5. Android Auto Specific Issues**

#### **Problem**: Location not available in Android Auto
**Solution**:
1. Ensure phone location is enabled
2. Grant location permission to **Android Auto** app
3. Enable **Developer Options** in Android Auto settings

### **6. Location Services Disabled**

#### **Problem**: Device location services turned off
**Solution**: The app will guide users, but you can check:
```bash
# Check if location services are enabled
adb shell settings get secure location_mode

# Enable location services (requires user interaction)
adb shell am start -a android.settings.LOCATION_SOURCE_SETTINGS
```

## 🧪 **Testing Commands**

### **Reset All Permissions (for testing)**
```bash
# Reset app permissions
adb shell pm reset-permissions com.roadtrip.copilot

# Clear app data
adb shell pm clear com.roadtrip.copilot

# Reinstall app
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

### **Check Permission Status**
```bash
# Check all permissions for the app
adb shell dumpsys package com.roadtrip.copilot | grep permission

# Check location permission specifically
adb shell dumpsys package com.roadtrip.copilot | grep ACCESS_FINE_LOCATION
adb shell dumpsys package com.roadtrip.copilot | grep ACCESS_BACKGROUND_LOCATION
adb shell dumpsys package com.roadtrip.copilot | grep POST_NOTIFICATIONS
```

### **Location Testing**
```bash
# Test location provider status
adb shell dumpsys location

# Check GPS status
adb shell dumpsys location | grep -A 10 "GPS"

# Monitor location requests
adb shell dumpsys location | grep -A 5 "com.roadtrip.copilot"
```

## 📱 **Step-by-Step User Testing**

### **Fresh Install Test**:
1. Uninstall app completely
2. Reinstall from Android Studio
3. Launch app and verify permission flow:
   - Location permission dialog appears
   - User taps "Allow" or "Allow only while using app"
   - (Android 13+) Notification permission dialog appears
   - (Optional) Background location dialog appears
4. Verify location updates are received

### **Permission Recovery Test**:
1. Go to **Settings → Apps → Roadtrip-Copilot → Permissions**
2. Deny location permission
3. Open app - should show location authorization screen
4. Tap "Enable Location Access"
5. Grant permission - app should proceed

### **Background Location Test**:
1. Enable background location when prompted
2. Put app in background
3. Drive/walk to different location
4. Return to app - should show updated location

## ⚡ **Performance Verification**

### **Location Update Frequency**
- Default: Every 5 seconds with 2-second minimum interval
- Check logs for "Location updated:" messages
- Should not drain battery significantly (<3% per hour)

### **Memory Usage**
```bash
# Monitor memory usage
adb shell dumpsys meminfo com.roadtrip.copilot

# Should stay under 150MB for location services
```

## 🔍 **Debugging Steps**

### **Enable Debug Logging**
1. Enable **Developer Options** on device
2. Enable **USB Debugging**
3. Run: `adb logcat | grep -i location`

### **Common Log Messages**
```
✅ "Location updates started successfully" - Working correctly
✅ "Location updated: lat, lon" - Receiving location data
❌ "Location permission not granted" - Permission issue
❌ "Location provider not available" - GPS/Network disabled
```

### **Priority Troubleshooting Order**
1. **Check device location services enabled**
2. **Verify app has location permissions granted**
3. **Test in different locations (not just one spot)**
4. **Check for device-specific battery optimizations**
5. **Test on physical device (not just emulator)**

## 🏁 **Success Criteria**

Your Android location authorization should be working when:
- ✅ App requests permissions in proper sequence
- ✅ Location updates appear in logs every few seconds
- ✅ Current location updates in UI ("Current City, CA")
- ✅ No "Location authorization not granted" errors
- ✅ Background location works for automotive features
- ✅ Notification permission doesn't block location services

## 🚨 **Still Having Issues?**

If location authorization still fails after following this guide:

1. **Check Android version compatibility** (API 29+ supported)
2. **Test on different devices/emulators**
3. **Verify Google Play Services are up to date**
4. **Check for manufacturer-specific restrictions**
5. **Review Android Auto setup if using in vehicle**

The implemented solution provides a robust, step-by-step permission flow that handles all Android version variations and edge cases for optimal roadtrip companion functionality.