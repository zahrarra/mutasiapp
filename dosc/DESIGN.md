---
name: Internal Asset Operations
colors:
  surface: '#FFFFFF'
  surface-dim: '#cddceb'
  surface-bright: '#f7f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#ecf4ff'
  surface-container: '#e1f0ff'
  surface-container-high: '#dbeaf9'
  surface-container-highest: '#d5e4f4'
  on-surface: '#0f1d28'
  on-surface-variant: '#42474d'
  inverse-surface: '#24323e'
  inverse-on-surface: '#e6f2ff'
  outline: '#72787d'
  outline-variant: '#c2c7cd'
  surface-tint: '#3b637d'
  primary: '#00273a'
  on-primary: '#ffffff'
  primary-container: '#0f3d56'
  on-primary-container: '#80a8c5'
  inverse-primary: '#a3cbea'
  secondary: '#006a63'
  on-secondary: '#ffffff'
  secondary-container: '#99efe5'
  on-secondary-container: '#006f67'
  tertiary: '#391d00'
  on-tertiary: '#ffffff'
  tertiary-container: '#54310a'
  on-tertiary-container: '#cc9969'
  error: '#B42318'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#c8e6ff'
  primary-fixed-dim: '#a3cbea'
  on-primary-fixed: '#001e2e'
  on-primary-fixed-variant: '#214b64'
  secondary-fixed: '#9cf2e8'
  secondary-fixed-dim: '#80d5cb'
  on-secondary-fixed: '#00201d'
  on-secondary-fixed-variant: '#00504a'
  tertiary-fixed: '#ffdcbf'
  tertiary-fixed-dim: '#f3bc89'
  on-tertiary-fixed: '#2d1600'
  on-tertiary-fixed-variant: '#643e17'
  background: '#F6F8FA'
  on-background: '#0f1d28'
  surface-variant: '#d5e4f4'
  text-primary: '#172B4D'
  text-secondary: '#52606D'
  border: '#D0D5DD'
  disabled: '#98A2B3'
  success: '#15803D'
  warning: '#B45309'
  info: '#175CD3'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: 0em
  title-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
    letterSpacing: 0em
  title-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0em
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0em
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.03em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
---

# DESIGN.md — MutasiKu

**Product:** MutasiKu  
**Platform:** Flutter Mobile  
**Purpose:** Aplikasi pengelolaan dan pelacakan mutasi aset internal  
**Version:** 1.0

## 1. Design Principles
- Status harus selalu terlihat (Status -> No. Tiket -> Informasi Aset -> Timeline -> Detail -> Action)
- Satu layar, satu tindakan utama (Primary: Ajukan Mutasi, Verifikasi, Setujui, dll.)
- Nuansa operasional perbankan internal (Professional, Reliable, Structured, Calm, Operational)

## 2. Visual Direction
- Modern asset tracking app
- Rounded cards (12px)
- Status badge (Icon + Text + Color)
- Timeline/Progress workflow
- Bottom navigation
- Bersih, no heavy gradients, no neon, no glassmorphism

## 3. Design Tokens
- Primary: #0F3D56 (Deep Navy)
- Secondary: #0F766E (Teal Accent)
- Background: #F6F8FA (Soft Cool Gray)
- Surface: #FFFFFF (White)
- Text Primary: #172B4D
- Text Secondary: #52606D
- Border: #D0D5DD
- Disabled: #98A2B3
- Success: #15803D
- Warning: #B45309
- Error: #B42318
- Info: #175CD3
- Font: Inter
- Radius: 12px (cards), 8px (buttons), 999px (badges)
