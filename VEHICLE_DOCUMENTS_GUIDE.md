# Vehicle Documents & Challans - Storage & Access Guide

## 📁 Where Everything is Stored

### **Storage Architecture**
- **Metadata**: Firestore (structured data)
- **PDF Files**: Google Drive (actual documents)

### **Firestore Collections**

#### 1. **`vehicle_documents`** Collection
Stores metadata for all uploaded vehicle documents with Google Drive file references

**Document Structure:**
```json
{
  "id": "doc-id-uuid",
  "bikeId": "bike-id",
  "userId": "user-id",
  "documentType": "rc|insurance|pollution|puc|other",
  "fileName": "RC_Certificate.pdf",
  "fileUrl": "https://drive.google.com/file/d/FILE_ID/view",
  "driveFileId": "FILE_ID",  // Google Drive file ID for operations
  "uploadedAt": "2026-01-15T10:30:00Z",
  "expiryDate": "2027-06-15T00:00:00Z",
  "description": "Original RC Certificate",
  "fileSizeBytes": 512000
}
```

**Queries Available:**
- All documents for a vehicle: `where('bikeId', isEqualTo: bikeId)`
- Documents by type: `where('bikeId', isEqualTo: bikeId).where('documentType', isEqualTo: 'rc')`
- Sorted by upload date: `orderBy('uploadedAt', descending: true)`

---

#### 2. **`challans`** Collection
Stores traffic violations/fines data for vehicles

**Document Structure:**
```json
{
  "id": "challan-id-uuid",
  "bikeId": "bike-id",
  "userId": "user-id",
  "registrationNumber": "KA01AB1234",
  "violationDate": "2026-01-10T15:45:00Z",
  "violationType": "speeding|parking|no-helmet|red-light|other",
  "fineAmount": 500.00,
  "location": "M.G. Road, Bangalore",
  "policeStation": "Whitefield Police Station",  // Optional
  "notes": "Caught by traffic camera",           // Optional
  "paymentDeadline": "2026-02-10T23:59:59Z",    // Optional
  "isPaid": false,
  "paidDate": null,
  "receiptUrl": null,                            // URL to payment receipt
  "createdAt": "2026-01-15T10:00:00Z"
}
```

**Queries Available:**
- All challans for a vehicle: `where('bikeId', isEqualTo: bikeId)`
- Unpaid challans: `where('bikeId', isEqualTo: bikeId).where('isPaid', isEqualTo: false)`
- Sorted by violation date: `orderBy('violationDate', descending: true)`

---

## 🔧 How to Use

### **1. Google Drive Service** (`google_drive_service.dart`)
Handles file uploads to Google Drive

```dart
final driveService = GoogleDriveService();

// Upload a vehicle document
final driveFileId = await driveService.uploadVehicleDocument(
  file: File('/path/to/rc.pdf'),
  bikeId: 'bike-123',
  documentType: 'rc'
);

// Get shareable link
final fileUrl = GoogleDriveService.getGoogleDriveFileUrl(driveFileId);

// Get preview URL
final previewUrl = GoogleDriveService.getGoogleDrivePreviewUrl(driveFileId);

// Upload challan receipt
final receiptId = await driveService.uploadChallanReceipt(
  file: File('/path/to/receipt.pdf'),
  bikeId: 'bike-123',
  challanId: 'challan-456'
);

// Delete file
await driveService.deleteFile(driveFileId);
```

### **2. Vehicle Documents Service** (`vehicle_document_service.dart`)
Uploads documents to Google Drive and registers metadata in Firestore

```dart
final documentService = VehicleDocumentService();

// Upload a document (automatically saves to Google Drive)
final doc = await documentService.uploadDocument(
  bikeId: 'bike-123',
  userId: 'user-456',
  documentType: 'rc',
  file: File('/path/to/rc.pdf'),
  expiryDate: DateTime(2027, 6, 15),
  description: 'Original RC'
);
// Returns: VehicleDocument with Google Drive link

// Register existing document
final doc = await documentService.registerDocument(
  bikeId: 'bike-123',
  userId: 'user-456',
  documentType: 'insurance',
  fileName: 'insurance.pdf',
  fileUrl: 'https://drive.google.com/file/d/FILE_ID/view',
  driveFileId: 'FILE_ID',
  expiryDate: DateTime(2027, 12, 31)
);

// Get all documents for a vehicle
final allDocs = await documentService.getVehicleDocuments('bike-123');

// Get only specific type
final rcDocs = await documentService.getVehicleDocumentsByType('bike-123', 'rc');

// Check expiring documents (within 30 days)
final expiringDocs = documentService.getExpiringDocuments(allDocs);

// Check expired documents
final expiredDocs = documentService.getExpiredDocuments(allDocs);

// Delete a document
await documentService.deleteDocument(doc);
```

---

### **3. Challan Service** (`challan_service.dart`)
```dart
final challanService = ChallanService();

// Create a new challan
final challan = await challanService.createChallan(
  bikeId: 'bike-123',
  userId: 'user-456',
  registrationNumber: 'KA01AB1234',
  violationDate: DateTime(2026, 1, 10),
  violationType: 'speeding',     // or 'parking', 'no-helmet', 'red-light', 'other'
  fineAmount: 500,
  location: 'M.G. Road, Bangalore',
  policeStation: 'Whitefield PS',
  paymentDeadline: DateTime(2026, 2, 10)
);

// Get all challans for a vehicle
final allChallans = await challanService.getVehicleChallans('bike-123');

// Get only unpaid challans
final unpaidChallans = await challanService.getUnpaidChallans('bike-123');

// Check overdue challans
final overdueChallans = challanService.getOverdueChallans(allChallans);

// Check expiring soon (7 days)
final expiringChallans = challanService.getExpiringChallans(allChallans);

// Mark challan as paid
await challanService.markChallanAsPaid('challan-id', receiptUrl: 'https://...');

// Get total pending fines
final totalFines = challanService.getTotalPendingFines(unpaidChallans);
```

---

### **4. Vehicle Management Provider** (`vehicle_management_provider.dart`)
Use this in your UI with Provider pattern:

```dart
// In main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => VehicleManagementProvider()),
  ],
  child: MyApp(),
)

// In your widget
final provider = context.read<VehicleManagementProvider>();

// Fetch documents
await provider.fetchVehicleDocuments('bike-123');
final docs = provider.documents;
final rcDocs = provider.rcDocuments;
final expiringDocs = provider.expiringDocuments;

// Register a document
await provider.registerDocument(
  bikeId: 'bike-123',
  userId: 'user-456',
  documentType: 'insurance',
  fileName: 'insurance.pdf',
  expiryDate: DateTime(2027, 12, 31)
);

// Fetch challans
await provider.fetchVehicleChallans('bike-123');
final allChallans = provider.challans;
final unpaidChallans = provider.unpaidChallans;
final overdueChallans = provider.overdueChallans;
final totalFines = provider.totalPendingFines;

// Create a challan
await provider.createChallan(
  bikeId: 'bike-123',
  userId: 'user-456',
  registrationNumber: 'KA01AB1234',
  violationDate: DateTime.now(),
  violationType: 'speeding',
  fineAmount: 500,
  location: 'M.G. Road'
);

// Mark challan as paid
await provider.markChallanAsPaid('challan-id');
```

## 💾 File Storage Strategy

### **Recommended Approach: Google Drive + Firestore**

**Benefits:**
- ✅ No additional packages needed (already using googleapis)
- ✅ Free 15GB storage per user
- ✅ Documents organized in folders by bike and type
- ✅ Easy sharing and access
- ✅ Automatic versioning
- ✅ Integrated with user's Google account

**Folder Structure in Google Drive:**
```
Nexus - Vehicle Documents/
├── Bike_bike-123/
│   ├── RC/
│   │   └── RC_Certificate.pdf
│   ├── INSURANCE/
│   │   └── policy.pdf
│   └── POLLUTION/
│       └── puc.pdf
└── Bike_bike-456/
    └── ...

Nexus - Challans/
├── Bike_bike-123/
│   ├── Challan_challan-id-1/
│   │   └── receipt.pdf
│   └── Challan_challan-id-2/
│       └── receipt.pdf
└── ...
```

**How it Works:**
1. User selects PDF from device
2. `GoogleDriveService` uploads to Google Drive automatically
3. Returns file ID + shareable link
4. `VehicleDocumentService` saves metadata to Firestore
5. Both are linked via the drive file ID

---

## 📊 Database Schema

### Firestore Structure
```
Firestore Database
├── vehicle_documents/
│   ├── doc-uuid-1
│   │   ├── bikeId: "bike-123"
│   │   ├── documentType: "rc"
│   │   ├── fileUrl: "..."
│   │   └── expiryDate: "2027-06-15"
│   ├── doc-uuid-2
│   └── ...
│
└── challans/
    ├── challan-uuid-1
    │   ├── bikeId: "bike-123"
    │   ├── violationType: "speeding"
    │   ├── fineAmount: 500
    │   ├── isPaid: false
    │   └── paymentDeadline: "2026-02-10"
    ├── challan-uuid-2
    └── ...
```

---

## 🔄 Next Steps

1. **Add Firebase Storage** to upload actual PDF files
2. **Create UI Screens** for:
   - Document upload & management
   - Challan tracking & payment
3. **Add Notifications** for expiring documents & overdue challans
4. **Integrate with Bike Provider** to link documents to bikes
5. **Add Export/Share** functionality for documents

---

## 📱 Usage in Screens

See `lib/modules/bike/` for example implementations:
- Create a new widget: `vehicle_documents_screen.dart`
- Create a new widget: `challans_screen.dart`
- Add tabs to existing bike detail screen
