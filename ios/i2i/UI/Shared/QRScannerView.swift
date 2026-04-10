import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    let onScan: (String) -> Void
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.onScan = onScan
        vc.onDismiss = onDismiss
        return vc
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

// MARK: -

final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onScan: ((String) -> Void)?
    var onDismiss: (() -> Void)?

    private var session: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        print("[QRScanner] viewDidLoad")
        checkPermissionAndSetup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("[QRScanner] viewWillAppear - starting session")
        guard let session = session else {
            print("[QRScanner] ERROR: No session available in viewWillAppear")
            return
        }
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
                print("[QRScanner] Session started in viewWillAppear")
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("[QRScanner] viewWillDisappear - stopping session")
        if session?.isRunning ?? false {
            session?.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    // MARK: - Setup

    private func checkPermissionAndSetup() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        print("[QRScanner] Camera permission status: \(status.rawValue)")
        
        switch status {
        case .authorized:
            print("[QRScanner] Camera permission already granted, setting up session")
            setupSession()
        case .notDetermined:
            print("[QRScanner] Requesting camera permission")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                print("[QRScanner] Camera permission granted: \(granted)")
                DispatchQueue.main.async {
                    if granted {
                        self?.setupSession()
                    } else {
                        self?.showPermissionDenied()
                    }
                }
            }
        default:
            print("[QRScanner] Camera permission denied or restricted")
            showPermissionDenied()
        }
    }

    private func setupSession() {
        print("[QRScanner] Setting up AVCaptureSession")
        
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        guard let device = AVCaptureDevice.default(for: .video) else {
            print("[QRScanner] ERROR: No video capture device available")
            showError("Camera not available")
            return
        }
        
        print("[QRScanner] Found video device: \(device.localizedName)")
        
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            print("[QRScanner] ERROR: Could not create AVCaptureDeviceInput")
            showError("Cannot access camera")
            return
        }
        
        guard session.canAddInput(input) else {
            print("[QRScanner] ERROR: Cannot add input to session")
            showError("Cannot configure camera")
            return
        }
        
        session.addInput(input)
        print("[QRScanner] Input added successfully")

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            print("[QRScanner] ERROR: Cannot add output to session")
            showError("Cannot configure camera")
            return
        }
        
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]
        print("[QRScanner] Output added successfully")

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        
        self.previewLayer = preview
        self.session = session
        
        print("[QRScanner] Starting capture session")
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
            print("[QRScanner] Capture session started")
        }
    }

    private func showPermissionDenied() {
        let label = UILabel()
        label.text = "Camera access required.\nEnable it in Settings."
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }
    
    private func showError(_ message: String) {
        print("[QRScanner] ERROR: \(message)")
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard
            let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            let value = object.stringValue
        else { return }

        session?.stopRunning()
        onScan?(value)
    }
}
