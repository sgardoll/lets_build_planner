# StoryFlow - Content Calendar Architecture

## Core Features
- **Undated Content Panel**: Left column showing all content items without scheduled dates
- **Monthly Calendar**: Right panel displaying current month with drag targets for each day
- **Drag & Drop**: Intuitive item scheduling by dragging from undated to calendar
- **Content Management**: Click to edit content items with full details form

## Data Model
**ContentItem** with fields:
- `id`: Unique identifier
- `title`: Content title
- `description`: Detailed description
- `url`: Associated URL
- `attachments`: List of attachment paths/URLs
- `dateScheduled`: When content should be published
- `datePublished`: Actual publish date
- `videoLink`: Video URL if applicable

## Core Components

### 1. HomePage (Main Calendar View)
- Split layout: 30% undated panel, 70% calendar
- Manages overall state and drag/drop coordination

### 2. UndatedContentPanel
- Scrollable list of unscheduled content items
- Drag sources for content items
- Add new content button

### 3. MonthlyCalendarPanel
- Current month display with day cells
- Drop targets for each day
- Navigation controls for month switching

### 4. ContentItemCard
- Draggable card showing item preview
- Click to open edit dialog
- Visual status indicators

### 5. ContentEditDialog
- Full-screen form for editing content details
- File attachment management
- Save/cancel actions

### 6. CalendarDayCell
- Individual day display
- Shows scheduled content for that day
- Drop target functionality

## Technical Implementation
- **State Management**: StatefulWidget with local state for simplicity
- **Drag & Drop**: Flutter's native Draggable/DragTarget widgets
- **Data Persistence**: SharedPreferences for local storage
- **Date Handling**: DateTime manipulation for calendar logic
- **Sample Data**: Pre-populated content items for demonstration

## File Structure
- `models/content_item.dart` - Data model
- `services/content_service.dart` - Data operations
- `screens/home_page.dart` - Main app screen
- `widgets/undated_panel.dart` - Left content panel
- `widgets/calendar_panel.dart` - Right calendar panel
- `widgets/content_card.dart` - Individual content items
- `widgets/content_dialog.dart` - Edit content form
- `widgets/calendar_day.dart` - Calendar day cells

## MVP Features
1. ✅ Display undated content items in left panel
2. ✅ Show monthly calendar on right with proper day layout
3. ✅ Drag and drop items from undated to calendar days
4. ✅ Click to edit content item details
5. ✅ Local storage persistence
6. ✅ Sample data for demonstration
7. ✅ Month navigation
8. ✅ Visual feedback during drag operations