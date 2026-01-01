# Hoor Manager - UI/UX Redesign

## Overview
This document outlines the changes made for the full UI/UX redesign of the Hoor Manager application. The goal was to create a modern, professional, and minimal interface suitable for a SaaS accounting product.

## Design System

### Colors
We have adopted a "Modern Professional" color palette:
- **Primary**: Deep Blue (`#12334E`) - Used for branding, headers, and primary actions.
- **Secondary**: Beige/Gold (`#E8D9C0`) - Used for accents and secondary elements.
- **Background**: Light Gray (`#F8F9FA`) - Used for the main background to reduce eye strain.
- **Surface**: White (`#FFFFFF`) - Used for cards and containers.
- **Functional Colors**:
  - Success: Green (`#28A745`)
  - Warning: Amber (`#FFC107`)
  - Error: Red (`#DC3545`)
  - Info: Cyan (`#17A2B8`)

### Typography
- **Font**: Cairo (Google Fonts)
- **Styles**: Clean, readable, and hierarchical.

### Components
- **Cards**: Flat design with subtle borders and rounded corners (Radius 12).
- **Buttons**: Minimalist with clear hierarchy.
- **Inputs**: Clean outlined borders with clear focus states.

## New Features

### Dashboard
A new `DashboardScreen` has been implemented to replace the old `HomeScreen`. It features:
- **Responsive Layout**: Adapts to different screen sizes (Drawer for navigation).
- **Stats Cards**: Key financial indicators (Sales, Expenses, Profit, Orders).
- **Charts Section**: Placeholder for sales analysis charts.
- **Recent Activity**: List of recent transactions.

## Restructuring
- **Navigation**: The `AppRouter` has been updated to use the `DashboardScreen` as the main entry point.
- **Theme**: `AppTheme` has been completely rewritten to reflect the new design system.

## Next Steps
1.  **Charts**: Implement actual charts using a library like `fl_chart`.
2.  **Screen Migration**: Review all other screens to ensure they fully align with the new design system (though the global theme update handles most of it).
3.  **Responsiveness**: Further test and refine layouts for Tablet and Web.
