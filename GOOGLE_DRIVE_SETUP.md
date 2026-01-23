# Vehicle Documents & Challans - Setup Complete ✅

## 📦 What's Been Implemented

You now have a complete system for managing vehicle documents and traffic challans with **Google Drive** + **Firestore**.

---

## 🗂️ Files Created

### **Models** (`lib/core/models/`)
- ✅ `vehicle_document.dart` - Document metadata model with Google Drive file ID
- ✅ `challan.dart` - Traffic violation/fine model

### **Services** (`lib/core/services/`)
- ✅ `google_drive_service.dart` - Handles file uploads to Google Drive
- ✅ `vehicle_document_service.dart` - Manages document uploads & Firestore storage
- ✅ `challan_service.dart` - Manages challan records in Firestore

### **Providers** (`lib/core/providers/`)
- ✅ `vehicle_management_provider.dart` - State management with convenient getters

### **UI Example** (`lib/modules/bike/screens/`)
- ✅ `vehicle_documents_screen.dart` - Complete example screen with file upload

### **Documentation**
- ✅ `VEHICLE_DOCUMENTS_GUIDE.md` - Full API reference
- ✅ `GOOGLE_DRIVE_SETUP.md` - This file

---

## 🚀 Quick Start

### **1. Add to `main.dart`**
```dart
import 'package:provider/provider.dart';
import 'core/providers/vehicle_management_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // ... existing providers
        ChangeNotifierProvider(create: (_) => VehicleManagementProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
```

### **2. Use in Your Widget**
```dart
// Fetch documents for a vehicle
final provider = context.read<VehicleManagementProvider>();
await provider.fetchVehicleDocuments(bikeId);

// Show documents
final docs = provider.rcDocuments;       // RC only
final allDocs = provider.documents;      // All types
final expiring = provider.expiringDocuments;

// Register document (uploads to Google Drive + saves to Firestore)
await provider.registerDocument(
  bikeId: 'bike-123',
  userId: 'user-456',
  documentType: 'rc',
  fileName: 'RC_Certificate.pdf',
  expiryDate: DateTime(2027, 6, 15),
  description: 'Original RC'
);
```

---

## 💾 Storage Architecture

```
┌─────────────────────────────────────────────────┐
│          Your App (Flutter)                      │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  Google Drive Service                    │  │
│  │  - Upload PDF files                      │  │
│  │  - Get shareable links                   │  │
│  │  - Organize in folders                   │  │
│  └────────────┬─────────────────────────────┘  │
│               │                                 │
│  ┌────────────▼─────────────────────────────┐  │
│  │  Vehicle Document Service                │  │
│  │  - Register documents                    │  │
│  │  - Track expiry dates                    │  │
│  │  - Check expiring/expired                │  │
│  └────────────┬─────────────────────────────┘  │
│               │                                 │
│  ┌────────────▼─────────────────────────────┐  │
│  │  Vehicle Management Provider             │  │
│  │  - UI-friendly state management          │  │
│  │  - Filtered queries (rc, insurance, etc) │  │
│  └────────────┬─────────────────────────────┘  │
│               │                                 │
└───────────────┼─────────────────────────────────┘
                │
      ┌─────────┴──────────┐
      │                    │
┌─────▼──────┐      ┌─────▼──────┐
│ Google      │      │ Firestore  │
│ Drive       │      │            │
│             │      │ Collections│
│ PDFs &      │      │ - vehicle_ │
│ Files       │      │   documents│
│             │      │ - challans │
└─────────────┘      │            │
                     └────────────┘
```

---

## 📱 Document Types Supported

- `rc` - Registration Certificate
- `insurance` - Insurance policy
- `pollution` - Pollution certificate
- `puc` - Pollution Under Control
- `other` - Custom documents

---

## 📊 Example Usage

### **Upload Document**
```dart
final provider = context.read<VehicleManagementProvider>();

// Picks file using file_picker
// Uploads to Google Drive
// Saves metadata to Firestore
// Updates UI automatically
final document = await provider.registerDocument(
  bikeId: widget.bike.id,
  userId: currentUserId,
  documentType: 'insurance',
  fileName: 'insurance_policy.pdf',
  expiryDate: DateTime(2027, 12, 31),
  description: 'Annual insurance policy'
);
```

### **Show Document Categories**
```dart
// RC Documents
provider.rcDocuments      // List of RC certificates

// Insurance Documents  
provider.insuranceDocuments  // List of insurance policies

// All Documents
provider.documents        // All documents for vehicle

// Alerts
provider.expiringDocuments   // Expiring in 30 days
provider.expiredDocuments    // Already expired
```

### **Manage Challans**
```dart
// Create challan
await provider.createChallan(
  bikeId: 'bike-123',
  userId: 'user-456',
  registrationNumber: 'KA01AB1234',
  violationDate: DateTime.now(),
  violationType: 'speeding',
  fineAmount: 500,
  location: 'M.G. Road, Bangalore',
  paymentDeadline: DateTime.now().add(Duration(days: 30))
);

// Check pending challans
provider.unpaidChallans      // Not yet paid
provider.overdueChallans     // Payment deadline passed
provider.expiringChallans    // Due in 7 days
provider.totalPendingFines   // Total amount pending
```

---

## 🔑 Key Features

✅ **Automatic Folder Organization**
- Files organized by bike and document type in Google Drive
- Easy to find and manage

✅ **Expiry Tracking**
- Set expiry dates on documents
- Automatic warnings for expiring/expired documents
- Customizable warning periods (default 30 days)

✅ **Firestore Integration**
- Metadata stored in Firestore for quick queries
- Links to Google Drive files
- No Firebase Storage needed

✅ **Challan Management**
- Track traffic violations
- Monitor payment status
- Get alerts for overdue challans
- Calculate total pending fines

✅ **Sharing Ready**
- Google Drive links are shareable
- Direct access to documents
- No need to download first

---

## 🎯 Real-World Flow

**Scenario: Vehicle owner uploads insurance certificate**

1. User clicks "Upload Insurance"
2. File picker opens → User selects PDF
3. `GoogleDriveService` uploads to Google Drive
4. Returns file ID + shareable link
5. `VehicleDocumentService` saves metadata to Firestore:
   - Document ID (UUID)
   - File URL (Google Drive link)
   - File ID (for future operations)
   - Expiry date (12/31/2027)
   - Upload date
6. `VehicleManagementProvider` updates UI
7. Document appears in insurance section
8. In 30 days, automatic alert if expiring soon

---

## 📝 Firestore Collections

### **`vehicle_documents`**
```
id: "doc-uuid-1"
├── bikeId: "bike-123"
├── userId: "user-456"
├── documentType: "insurance"
├── fileName: "policy.pdf"
├── fileUrl: "https://drive.google.com/file/d/abc123/view"
├── driveFileId: "abc123"  ← Use this to delete from Drive
├── uploadedAt: "2026-01-15T10:30:00Z"
├── expiryDate: "2027-12-31T00:00:00Z"
├── description: "Annual insurance"
└── fileSizeBytes: 512000
```

### **`challans`**
```
id: "challan-uuid-1"
├── bikeId: "bike-123"
├── userId: "user-456"
├── registrationNumber: "KA01AB1234"
├── violationDate: "2026-01-10T15:45:00Z"
├── violationType: "speeding"
├── fineAmount: 500
├── location: "M.G. Road"
├── paymentDeadline: "2026-02-10T23:59:59Z"
├── isPaid: false
├── paidDate: null
├── receiptUrl: null
└── createdAt: "2026-01-15T10:00:00Z"
```

---

## ⚡ Performance Tips

1. **Batch Uploads** - Upload multiple documents at once
2. **Cache Documents** - Load once per session
3. **Filter by Type** - Use `getVehicleDocumentsByType()` for quick access
4. **Lazy Load** - Load documents only when needed
5. **Archive Old** - Delete old challans after payment

---

## 🐛 Troubleshooting

**Problem:** Files not uploading
- Check Google Sign-In is working
- Verify internet connection
- Check Firestore permissions

**Problem:** Documents showing but no Google Drive folder created
- User might not have signed in to Google
- Check Google Drive access permissions
- Ensure googleapis package is properly configured

**Problem:** Expiry dates not showing
- Make sure expiry date is set when uploading
- Check date format: Must be `DateTime` object

---

## 📚 API Reference

See [VEHICLE_DOCUMENTS_GUIDE.md](VEHICLE_DOCUMENTS_GUIDE.md) for complete API documentation.

### Quick Links:
- `GoogleDriveService` - File upload operations
- `VehicleDocumentService` - Document management
- `ChallanService` - Challan operations
- `VehicleManagementProvider` - UI state management

---

## ✨ Example Screen

See `lib/modules/bike/screens/vehicle_documents_screen.dart` for a complete working example showing:
- Upload buttons for each document type
- Document galleries by category
- Expiry warnings
- Direct opening of documents in Google Drive
- Delete functionality

---

## 🔐 Security Considerations

1. **Google Drive Permissions**
   - Only authorized user can upload
   - Docs created in user's private folder

2. **Firestore Rules**
   - Add rules to restrict access to user's own documents
   ```js
   match /vehicle_documents/{document=**} {
     allow read, write: if request.auth.uid == resource.data.userId;
   }
   ```

3. **File Sharing**
   - Google Drive links are shareable but private by default
   - Users can share links with family/insurance company

---

## 🚀 Next Steps

1. ✅ Created models & services
2. ✅ Created providers
3. ✅ Created example screen
4. 📝 TODO: Add to your existing bike detail screen
5. 📝 TODO: Add notifications for expiring documents
6. 📝 TODO: Add challan listing screen
7. 📝 TODO: Add payment integration for challans

---

## 📞 Support

All services are fully documented with examples. Check inline comments in:
- `google_drive_service.dart`
- `vehicle_document_service.dart`
- `challan_service.dart`
- `vehicle_documents_screen.dart`
