# Figma Plugin Publishing — Complete Checklist

## Pre-Submission Checklist

### ✅ Functionality & Stability
- [ ] Plugin works with no selection
- [ ] Plugin works with single node selection
- [ ] Plugin works with multiple nodes selected
- [ ] Plugin works on empty pages
- [ ] Plugin works on large files (100+ layers)
- [ ] Plugin handles locked layers gracefully
- [ ] Plugin handles components, instances, and variants
- [ ] Plugin handles different node types (frames, groups, text, vectors)
- [ ] Proper error handling — no uncaught exceptions
- [ ] Loading states shown for async operations
- [ ] Plugin doesn't freeze Figma UI during operations
- [ ] Memory: no leaks from event listeners or intervals
- [ ] Timeout handling for API calls

### ✅ Technical Compliance
- [ ] `manifest.json` has all required fields
- [ ] `id` field is set (from Figma's "Create new plugin" dialog)
- [ ] `api` is set to latest stable version
- [ ] `documentAccess` is set to `"dynamic-page"`
- [ ] `networkAccess` lists only needed domains (if applicable)
- [ ] `permissions` includes only what's needed
- [ ] Uses only supported Plugin API methods
- [ ] No deprecated API usage
- [ ] Bundle size is reasonable (< 5MB preferred)

### ✅ User Experience
- [ ] Clear, descriptive plugin name
- [ ] Plugin provides feedback via `figma.notify()` for actions
- [ ] Error messages are user-friendly (not raw error objects)
- [ ] UI matches Figma's design language (light/dark theme support)
- [ ] UI is responsive within the plugin window
- [ ] Keyboard navigation works in plugin UI
- [ ] "Close" / "Cancel" actions available where appropriate

### ✅ Icon & Branding
- [ ] Plugin icon is at least 128×128px
- [ ] Icon is clear and legible at small sizes (16px, 24px, 32px)
- [ ] Icon represents the plugin's function
- [ ] Icon is unique and distinguishable
- [ ] No use of Figma's logo without permission

### ✅ Documentation & Support
- [ ] Clear, compelling description (what it does + who it's for)
- [ ] Screenshots showing the plugin in action (recommended: 3-5)
- [ ] Instructions / "getting started" info in description
- [ ] Support contact (email, website, or help center link)
- [ ] Privacy policy URL (required if collecting/processing user data)
- [ ] Changelog for updates (recommended)

### ✅ Legal & Privacy
- [ ] Complies with Figma Developer Terms
- [ ] Complies with Figma Creator Agreement
- [ ] Complies with Figma Community Terms
- [ ] Privacy policy provided (if applicable)
- [ ] No copyrighted material used without permission
- [ ] No misleading claims about functionality
- [ ] Monetization follows Figma guidelines (if applicable)

## Publishing Steps

### First-Time Publish
1. Open Figma Desktop App
2. Go to **Plugins → Development → Manage plugins in development**
3. Find your plugin → click `...` menu → **Publish**
4. Fill in all required metadata:
   - **Plugin Name** — Clear and descriptive
   - **Tagline** — One-line summary
   - **Description** — Detailed explanation with features
   - **Icon** — At least 128×128px
   - **Cover Art** — Recommended 1920×960px
   - **Screenshots** — At least 1, recommended 3-5
   - **Tags / Categories** — Help discoverability
   - **Support URL** — Required
   - **Privacy Policy URL** — Required if collecting data
5. Click **Submit for Review**

### Review Process
- **Timeline:** Typically 5-10 business days
- **Criteria:** Functionality, performance, security, content quality
- **Outcome:** Approved (published) or rejected with feedback
- **Updates:** Material changes trigger re-review

### Updating a Published Plugin
1. Make your code changes
2. Build the production bundle
3. Go to **Plugins → Development → Manage plugins in development**
4. Click `...` on your plugin → **Publish new version**
5. Update version notes (changelog)
6. Submit

## Community Listing Best Practices

### Compelling Description Template
```
[Plugin Name] helps [target audience] to [core value proposition].

## Features
• Feature 1 — brief benefit description
• Feature 2 — brief benefit description
• Feature 3 — brief benefit description

## How to Use
1. Select your layers
2. Run [Plugin Name]
3. Configure options in the panel
4. Click "Apply"

## Support
Need help? Visit [support URL] or email [email].
```

### Screenshot Guidelines
- Show the plugin in action within Figma
- Annotate key features with callouts
- Include before/after comparisons where relevant
- Use real-world examples, not placeholder content
- Ensure text is readable at thumbnail size

## Common Rejection Reasons
1. Plugin doesn't work as described
2. Missing or inadequate error handling
3. UI doesn't match Figma's design standards
4. Performance issues (freezing or very slow)
5. Missing privacy policy when collecting data
6. Misleading description or screenshots
7. Using deprecated or unsupported APIs
8. Security concerns (excessive permissions, data leaks)
