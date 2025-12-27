# SealZero Branding Guide

## Logo & Icon Assets

### Primary Logo
- **File**: `web/icons/logo.svg`
- **Usage**: Marketing materials, social media, documentation
- **Format**: SVG (scalable)

### Favicon
- **File**: `web/favicon.svg`
- **Usage**: Browser tabs, bookmarks
- **Fallback**: `web/favicon.png` (32x32px)

### Design Concept
**"Zero with Shield"**
- Circular "0" shape representing zero-knowledge
- Shield inside representing security/authenticity
- Checkmark symbolizing verification

## Color Palette

### Primary Gradient
- **Start**: `#4F46E5` (Indigo 600)
- **End**: `#7C3AED` (Purple 600)
- **Usage**: Headers, CTAs, brand elements

### Accent Colors
- **White**: `#FFFFFF` (backgrounds, contrast)
- **Dark Purple**: `#5B21B6` (hover states)

## Typography

### Headers
- **Font**: System fonts (San Francisco, Segoe UI, Roboto)
- **Weight**: Bold (700)
- **Style**: Clean, modern, professional

### Body
- **Font**: Noto Sans (loaded from Google Fonts)
- **Weight**: Regular (400), Medium (500)

## Brand Voice

**Tagline**: "Prove without revealing"

**Key Messages**:
- Zero-knowledge cryptography
- Privacy-preserving authentication
- Mathematically secure proofs
- No secrets shared

**Tone**:
- Professional but approachable
- Technical but clear
- Secure but user-friendly

## Icon Usage

### When to Use Logo
✅ Marketing materials
✅ Social media posts  
✅ Documentation headers
✅ App splash screens

### When to Use Favicon
✅ Browser tabs
✅ Bookmarks
✅ PWA icons

## Generating PNG Assets

If you need PNG versions for specific platforms:

```bash
# Using Inkscape (command line)
inkscape favicon.svg --export-filename=favicon.png --export-width=32 --export-height=32

# Using ImageMagick
convert -density 1200 -resize 192x192 logo.svg Icon-192.png
convert -density 1200 -resize 512x512 logo.svg Icon-512.png
```

Or use online tools:
- https://cloudconvert.com/svg-to-png
- https://svgtopng.com/

## Social Media Specifications

### Twitter/X
- **Profile**: 400x400px (use logo.svg converted)
- **Header**: 1500x500px (gradient background + logo)

### LinkedIn
- **Profile**: 400x400px
- **Banner**: 1584x396px

### GitHub
- **Social Preview**: 1280x640px (OG image)

## Website Usage

Current implementation:
- Header: "SealZero" text with gradient background
- Icon: Shield symbol (from Material Icons)
- Future: Replace with custom SVG logo

---

**Brand Created**: December 27, 2025
**Domain**: www.sealzero.dev
**Repository**: github.com/PiotrStyla/Imageproof
