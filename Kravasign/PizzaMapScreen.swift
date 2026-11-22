import SwiftUI
import MapKit
import CoreLocation

struct PizzaPlace: Identifiable {
    let id: String
    let item: MKMapItem
    var name: String { item.name ?? "Pizza shop" }
    var address: String { item.placemark.title ?? "" }
}

final class PizzaFinder: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var places: [PizzaPlace] = []
    @Published var position: CLLocationCoordinate2D?
    @Published var selected: PizzaPlace?
    @Published var status = "Looking for pizza near you…"
    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 34.3542, longitude: -119.0593), latitudinalMeters: 11000, longitudinalMeters: 11000)
    private let locationManager = CLLocationManager()
    private var lastSearch: CLLocation?
    private var search: MKLocalSearch?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func start() {
        switch locationManager.authorizationStatus {
        case .notDetermined: locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways: locationManager.startUpdatingLocation()
        default:
            status = "Enable Location in Settings, or explore the map manually."
            findPizza(around: region)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        } else if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            status = "Location unavailable. Explore the map to find pizza."
            findPizza(around: region)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newest = locations.last else { return }
        position = newest.coordinate
        if let previous = lastSearch, newest.distance(from: previous) < 1200 { return }
        lastSearch = newest
        region = MKCoordinateRegion(center: newest.coordinate, latitudinalMeters: 9000, longitudinalMeters: 9000)
        findPizza(around: region)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        status = "Location unavailable. Move the map and tap Search Here."
    }

    func findPizza(around mapRegion: MKCoordinateRegion) {
        search?.cancel()
        status = "Hunting for pizza…"
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "pizza restaurant"
        request.resultTypes = .pointOfInterest
        request.region = mapRegion
        let task = MKLocalSearch(request: request)
        search = task
        task.start { [weak self] response, error in
            guard let self = self, self.search === task else { return }
            guard let response = response else {
                self.places = []
                self.status = "Couldn't load shops. Check your connection and retry."
                return
            }
            // MapKit's search can return loosely related businesses; verify the listing.
            let candidates = response.mapItems.filter { item in
                let name = (item.name ?? "").lowercased()
                let category = item.pointOfInterestCategory
                return category == .restaurant && (name.contains("pizza") || name.contains("pizzeria") || name.contains("pizz"))
                    || name.contains("pizza") || name.contains("pizzeria")
            }
            self.places = candidates.map { PizzaPlace(id: "\($0.placemark.coordinate.latitude),\($0.placemark.coordinate.longitude)", item: $0) }
            self.status = self.places.isEmpty ? "No pizza shops found here. Try another area!" : "\(self.places.count) pizza spots found 🍕"
        }
    }

    func directions(to place: PizzaPlace) {
        place.item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

struct PizzaMapScreen: View {
    @StateObject private var finder = PizzaFinder()

    var body: some View {
        ZStack {
            PizzaMapView(finder: finder)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                header
                Spacer()
                if let place = finder.selected { shopCard(place) }
                controls
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .preferredColorScheme(.light)
        .onAppear { finder.start() }
    }

    private var header: some View {
        VStack(spacing: 4) {
            HStack(spacing: 9) {
                Text("🍕").font(.system(size: 36))
                VStack(alignment: .leading, spacing: 1) {
                    Text("PIZZA PLANET").font(.system(size: 23, weight: .black, design: .rounded)).tracking(1)
                    Text("YOUR CHEESY GPS ADVENTURE").font(.system(size: 10, weight: .heavy, design: .rounded)).tracking(1.2)
                }
                Spacer()
            }
            Text(finder.status)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundColor(Color(red: 0.43, green: 0.13, blue: 0.08))
        .padding(16)
        .background(Color(red: 1, green: 0.82, blue: 0.36), in: RoundedRectangle(cornerRadius: 23))
        .overlay(RoundedRectangle(cornerRadius: 23).stroke(Color(red: 0.74, green: 0.27, blue: 0.11), lineWidth: 3))
        .shadow(color: .brown.opacity(0.23), radius: 9, y: 5)
    }

    private func shopCard(_ place: PizzaPlace) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("🍕  " + place.name).font(.system(size: 21, weight: .black, design: .rounded))
                Spacer()
                Button { finder.selected = nil } label: { Image(systemName: "xmark.circle.fill").font(.title2) }
            }
            Text(place.address).font(.subheadline)
            Button { finder.directions(to: place) } label: {
                Label("LET'S GET PIZZA!", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity).padding(13)
            }
            .buttonStyle(.plain)
            .background(Color(red: 0.84, green: 0.19, blue: 0.11), in: Capsule())
            .foregroundColor(.white)
        }
        .foregroundColor(Color(red: 0.38, green: 0.16, blue: 0.07))
        .padding(16)
        .background(Color(red: 1, green: 0.94, blue: 0.73), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(.brown, lineWidth: 2))
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button { finder.findPizza(around: finder.region) } label: {
                Label("SEARCH HERE", systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            Button {
                if let coordinate = finder.position {
                    finder.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 9000, longitudinalMeters: 9000)
                    finder.findPizza(around: finder.region)
                } else { finder.start() }
            } label: { Image(systemName: "location.fill").frame(width: 25) }
        }
        .font(.system(size: 15, weight: .black, design: .rounded))
        .padding(16)
        .foregroundColor(.white)
        .background(Color(red: 0.76, green: 0.21, blue: 0.12), in: Capsule())
        .shadow(radius: 5, y: 3)
    }
}

struct PizzaMapView: UIViewRepresentable {
    @ObservedObject var finder: PizzaFinder

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        let config = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
        config.pointOfInterestFilter = .excludingAll
        map.preferredConfiguration = config
        map.showsUserLocation = true
        map.delegate = context.coordinator
        map.setRegion(finder.region, animated: false)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        context.coordinator.parent = self
        if map.annotations.filter({ !($0 is MKUserLocation) }).count != finder.places.count || context.coordinator.lastIDs != finder.places.map(\.id) {
            map.removeAnnotations(map.annotations.filter { !($0 is MKUserLocation) })
            for place in finder.places {
                let marker = PizzaAnnotation(place: place)
                map.addAnnotation(marker)
            }
            context.coordinator.lastIDs = finder.places.map(\.id)
        }
        let delta = abs(map.region.center.latitude - finder.region.center.latitude) + abs(map.region.center.longitude - finder.region.center.longitude)
        if delta > 0.025 { map.setRegion(finder.region, animated: true) }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: PizzaMapView
        var lastIDs: [String] = []
        init(_ parent: PizzaMapView) { self.parent = parent }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard annotation is PizzaAnnotation else { return nil }
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: "pizza")
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 53, height: 53))
            label.text = "🍕"
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 37)
            label.backgroundColor = UIColor(red: 1, green: 0.87, blue: 0.43, alpha: 0.94)
            label.layer.cornerRadius = 26.5
            label.layer.borderColor = UIColor(red: 0.66, green: 0.26, blue: 0.12, alpha: 1).cgColor
            label.layer.borderWidth = 3
            label.clipsToBounds = true
            view.addSubview(label)
            view.frame = label.bounds
            view.centerOffset = CGPoint(x: 0, y: -22)
            view.canShowCallout = false
            return view
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let marker = view.annotation as? PizzaAnnotation else { return }
            parent.finder.selected = marker.place
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.finder.region = mapView.region
        }
    }
}

final class PizzaAnnotation: NSObject, MKAnnotation {
    let place: PizzaPlace
    var coordinate: CLLocationCoordinate2D { place.item.placemark.coordinate }
    var title: String? { place.name }
    init(place: PizzaPlace) { self.place = place }
}
