# Instructions to Fix the iOS Build

## Manual Steps Required

### Step 1: Add Files to Xcode Project

1. Open `/Users/naderrahimizad/Projects/AI/POICompanion/mobile/ios/RoadtripCopilot.xcodeproj` in Xcode

2. In the project navigator, right-click on the "Models" group

3. Select "Add Files to RoadtripCopilot..."

4. Navigate to `/Users/naderrahimizad/Projects/AI/POICompanion/mobile/ios/RoadtripCopilot/Models/`

5. Select these files:
   - `AutoDiscoverManager.swift`
   - `POIRankingEngine.swift`
   - `POI.swift`

6. Ensure these options are checked:
   - ✅ Copy items if needed (should be unchecked since files are already there)
   - ✅ Add to targets: RoadtripCopilot

7. Click "Add"

### Step 2: Fix Provisioning Profile

1. In Xcode, select the RoadtripCopilot project in the navigator

2. Select the RoadtripCopilot target

3. Go to "Signing & Capabilities" tab

4. Fix the provisioning profile issues:
   - The profile needs these entitlements:
     - com.apple.developer.background-modes
     - com.apple.developer.carplay-audio
     - com.apple.developer.carplay-navigation
     - com.apple.developer.location.when-in-use

5. Either:
   - Let Xcode automatically manage signing (recommended)
   - Or manually update the provisioning profile in Apple Developer portal

### Step 3: Verify the Build

```bash
cd /Users/naderrahimizad/Projects/AI/POICompanion/mobile/ios
xcodebuild -project RoadtripCopilot.xcodeproj -scheme RoadtripCopilot -configuration Debug build
```

### Step 4: Check SetDestinationScreen.swift

The file `/Users/naderrahimizad/Projects/AI/POICompanion/mobile/ios/RoadtripCopilot/Views/SetDestinationScreen.swift` also needs to be added if it doesn't exist, or the Auto Discover button code needs to be added to the existing destination selection screen.

## Alternative: Programmatic Fix (Advanced)

If you want to add files programmatically to the Xcode project:

### Option 1: Using Ruby and xcodeproj gem

```bash
# Install the gem
gem install xcodeproj

# Create a Ruby script
cat > add_files.rb << 'EOF'
require 'xcodeproj'

project_path = 'RoadtripCopilot.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'RoadtripCopilot' }
models_group = project.main_group['RoadtripCopilot']['Models']

files_to_add = [
  'RoadtripCopilot/Models/AutoDiscoverManager.swift',
  'RoadtripCopilot/Models/POIRankingEngine.swift',
  'RoadtripCopilot/Models/POI.swift'
]

files_to_add.each do |file_path|
  file_ref = models_group.new_file(file_path)
  target.add_file_references([file_ref])
end

project.save
puts "Files added successfully!"
EOF

# Run it
ruby add_files.rb
```

### Option 2: Using Python with mod-pbxproj

```bash
# Install the package
pip install pbxproj

# Create a Python script
cat > add_files.py << 'EOF'
from pbxproj import XcodeProject

project = XcodeProject.load('RoadtripCopilot.xcodeproj/project.pbxproj')

files = [
    'RoadtripCopilot/Models/AutoDiscoverManager.swift',
    'RoadtripCopilot/Models/POIRankingEngine.swift',
    'RoadtripCopilot/Models/POI.swift'
]

for file_path in files:
    project.add_file(file_path, target_name='RoadtripCopilot')

project.save()
print("Files added successfully!")
EOF

# Run it
python add_files.py
```

## After Fixing the Build

Once the build is working, you can:

1. Run actual tests (not simulated)
2. Verify the Auto Discover feature works
3. Test on real simulator/device

## Note on MCP Tools

The MCP tools need enhancement to:
1. Actually modify Xcode project files
2. Run real builds and report actual errors
3. Execute real tests instead of simulating

Until then, manual intervention is required for iOS development.