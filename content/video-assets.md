# YouTube Video Assets

This document outlines the visual assets needed for the pgschema YouTube video.

## 🎨 Thumbnail Design Specifications

### Main Thumbnail
- **Dimensions**: 1280x720 pixels (16:9 aspect ratio)
- **File Format**: JPG or PNG
- **File Size**: Under 2MB

### Design Elements
```
[LEFT SIDE - Traditional Approach]
❌ TRADITIONAL MIGRATIONS
- migration_001.sql
- migration_002.sql  
- migration_003.sql
- migration_004.sql ❌ FAILED
[Red background, messy code snippets]

[RIGHT SIDE - pgschema Approach]  
✅ PGSCHEMA
- schema.sql (single file)
- Clean, declarative code
[Green/blue background, clean design]

[CENTER]
Large text: "STOP Writing DB Migrations"
pgschema logo
```

### Color Scheme
- **Traditional Side**: Red (#FF4444), dark gray (#333333)
- **pgschema Side**: Blue (#0066CC), green (#00AA44)
- **Text**: White (#FFFFFF) with dark outline
- **Background**: Gradient from red to blue

### Typography
- **Main Text**: Bold, sans-serif font (Arial Black or similar)
- **Code Text**: Monospace font (Consolas or similar)
- **Size**: Large enough to read on mobile devices

## 📺 Title Cards

### Opening Title Card
```
[Background: pgschema gradient]
[Large text]: Stop Writing Database Migrations
[Subtitle]: Transform PostgreSQL Schema Management
[Logo]: pgschema logo
[Duration]: 3 seconds
```

### Section Title Cards
```
1. "The Problem with Traditional Migrations"
   - Red background with error icons
   
2. "Traditional Migration Disaster"
   - Dark background with terminal/error theme
   
3. "pgschema Solution Demo"
   - Blue/green gradient with pgschema logo
   
4. "Advanced PostgreSQL Features"
   - PostgreSQL elephant logo with modern design
   
5. "GitOps Integration"
   - GitHub/CI/CD themed graphics
   
6. "Getting Started"
   - Bright, encouraging colors
```

## 📊 Comparison Graphics

### Traditional vs pgschema Workflow
```
[LEFT COLUMN - Traditional]
Developer writes migration_001.sql
↓
Developer writes migration_002.sql  
↓
Developer writes migration_003.sql
↓
Migration fails in production ❌
↓
Manual recovery required
↓
Downtime and stress

[RIGHT COLUMN - pgschema]
Developer edits schema.sql
↓
pgschema plan shows changes
↓
Team reviews plan
↓
pgschema apply executes safely ✅
↓
Automatic rollback on failure
↓
Zero downtime
```

### Benefits Comparison Table
```
| Aspect                | Traditional | pgschema |
|-----------------------|-------------|----------|
| Migration Writing     | Manual ❌   | Auto ✅  |
| Schema Drift          | Manual ❌   | Auto ✅  |
| Rollback Procedures   | Manual ❌   | Auto ✅  |
| Multi-Environment     | Complex ❌  | Simple ✅|
| Team Collaboration    | Hard ❌     | Easy ✅  |
| PostgreSQL Features   | Limited ❌  | Full ✅  |
```

## 🎬 Screen Recording Assets

### Terminal Theme
```
Background: Dark (#1E1E1E)
Text: Light gray (#D4D4D4)
Success: Green (#4EC9B0)
Error: Red (#F44747)
Warning: Yellow (#FFCC02)
Highlight: Blue (#569CD6)
```

### Code Editor Theme
- **Editor**: VS Code with PostgreSQL extension
- **Theme**: Dark+ (default dark)
- **Font**: Fira Code or Consolas, size 14-16
- **Syntax Highlighting**: PostgreSQL/SQL

### Browser Setup
- **Clean bookmarks bar**: Remove personal bookmarks
- **GitHub theme**: Use GitHub's clean interface
- **Zoom level**: 125% for better readability

## 🎵 Audio Assets

### Background Music
- **Intro/Outro**: Upbeat, tech-focused instrumental
- **Demo Sections**: Subtle, non-distracting background music
- **Volume**: 20-30% of narration volume
- **Style**: Modern, professional, optimistic

### Sound Effects
- **Success sounds**: For successful operations
- **Error sounds**: For failed migrations (traditional approach)
- **Transition sounds**: Subtle whoosh for section changes
- **Typing sounds**: For code editing segments (optional)

## 📱 Mobile Optimization

### Text Readability
- **Minimum font size**: 24px for mobile viewing
- **High contrast**: Ensure text is readable on small screens
- **Simple layouts**: Avoid cluttered designs

### Visual Hierarchy
- **Most important info**: Largest and most prominent
- **Secondary info**: Medium size, good contrast
- **Supporting details**: Smaller but still readable

## 🎯 Animation Specifications

### Code Highlighting
```css
.code-highlight {
  background: rgba(86, 156, 214, 0.3);
  border-left: 3px solid #569CD6;
  animation: fadeIn 0.5s ease-in;
}
```

### Transition Effects
- **Fade in/out**: 0.3-0.5 seconds
- **Slide transitions**: Smooth, not jarring
- **Zoom effects**: For emphasizing important points
- **Progress bars**: For long operations

### Error Animations
- **Shake effect**: For failed operations
- **Red flash**: For error states
- **Cross-out**: For deprecated approaches

## 📋 Asset Checklist

### Pre-Production
- [ ] Thumbnail design created and tested
- [ ] Title cards designed for all sections
- [ ] Comparison graphics prepared
- [ ] Terminal and editor themes configured
- [ ] Background music selected and licensed
- [ ] Sound effects prepared

### During Recording
- [ ] Screen resolution set to 1920x1080+
- [ ] Audio levels tested and optimized
- [ ] Lighting setup for any on-camera segments
- [ ] Backup recording setup ready

### Post-Production
- [ ] Captions/subtitles added
- [ ] Code highlighting applied
- [ ] Background music mixed at appropriate levels
- [ ] Transition effects added
- [ ] YouTube cards and end screen configured

## 🔧 Technical Specifications

### Video Export Settings
- **Resolution**: 1920x1080 (1080p)
- **Frame Rate**: 30fps
- **Bitrate**: 8-12 Mbps for high quality
- **Audio**: 48kHz, 320kbps AAC
- **Format**: MP4 (H.264)

### File Organization
```
video-assets/
├── thumbnails/
│   ├── main-thumbnail.png
│   ├── thumbnail-variants/
│   └── thumbnail-source.psd
├── title-cards/
│   ├── opening-title.png
│   ├── section-titles/
│   └── title-card-template.psd
├── graphics/
│   ├── comparison-charts/
│   ├── workflow-diagrams/
│   └── icons/
├── audio/
│   ├── background-music/
│   ├── sound-effects/
│   └── voice-over/
└── screen-recordings/
    ├── raw-footage/
    ├── edited-segments/
    └── final-export/
```

## 🎨 Brand Guidelines

### pgschema Brand Colors
- **Primary Blue**: #0066CC
- **Secondary Green**: #00AA44
- **Accent Gray**: #666666
- **Background**: #F8F9FA
- **Text**: #212529

### Logo Usage
- **Minimum size**: 100px width for digital use
- **Clear space**: Equal to the height of the logo
- **Backgrounds**: Use on light backgrounds, white version for dark
- **File formats**: SVG for scalability, PNG for raster use

### Typography
- **Primary**: Inter or similar modern sans-serif
- **Code**: Fira Code or Consolas monospace
- **Headings**: Bold weights (600-700)
- **Body**: Regular weight (400)

This comprehensive asset guide ensures professional, consistent visual presentation that effectively communicates pgschema's value proposition to the PostgreSQL community.