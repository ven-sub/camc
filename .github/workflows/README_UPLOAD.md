# Upload to TestFlight Workflow

## Purpose
This workflow allows you to upload an existing IPA file to TestFlight without rebuilding the entire app. Useful when:
- A build succeeded but upload failed
- You want to re-upload an existing build
- You have a locally built IPA to upload

## How to Use

### Option 1: Upload from Previous Build Artifact (Most Common)
1. Go to: **Actions** tab in GitHub
2. Click: **Upload to TestFlight** workflow (left sidebar)
3. Click: **Run workflow** button (right side)
4. Fill in:
   - **artifact_name**: `camc-ios-main` (or `camc-ios-{your-branch}`)
   - **run_id**: Leave empty (will use latest successful build)
   - **ipa_path**: Leave empty
5. Click: **Run workflow**

The workflow will:
- Download the artifact from the latest successful iOS build
- Find the IPA file
- Upload to TestFlight
- Complete in ~1-2 minutes

**Note:** The artifact is downloaded from the latest successful run of the `build-ios.yml` workflow. If you need a specific build, provide the `run_id`.

### Option 2: Upload Specific IPA (Advanced)
If you have the IPA file path available in the runner:
1. Follow steps 1-3 above
2. Fill in:
   - **ipa_path**: Full path to IPA file
   - Leave other fields empty
3. Click: **Run workflow**

## Finding Artifact Information

### Get Artifact Name:
- Format: `camc-ios-{branch}`
- Example: `camc-ios-main` for main branch
- Example: `camc-ios-feature-xyz` for feature branch

### Get Run ID (Optional):
1. Go to **Actions** tab
2. Click on the build you want
3. Look at URL: `https://github.com/user/repo/actions/runs/XXXXXXXXXX`
4. The number is the run_id

## After Upload

Once the upload completes successfully:
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to: **My Apps** → **Circuit Assistant MoCom** → **TestFlight**
3. Wait 5-15 minutes for Apple to process the build
4. Click on the new build
5. Enable it for **MoCom Testers** group
6. Testers will be notified automatically

## Troubleshooting

### "No IPA file found in artifact"
- Check that the artifact name is correct
- Verify the artifact exists in the Actions run
- Ensure the artifact contains an IPA file

### "Upload failed"
- Check that App Store Connect API secrets are configured
- Verify the IPA file is valid and signed correctly
- Check the workflow logs for detailed error messages

## Integration with Main Build

The main build workflow (`build-ios.yml`) automatically:
1. Builds the iOS app
2. Creates an IPA
3. Saves it as an artifact (`camc-ios-{branch}`)
4. Attempts to upload to TestFlight

If step 4 fails, you can use this upload workflow to retry without rebuilding.

