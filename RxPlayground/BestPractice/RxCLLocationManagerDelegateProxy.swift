//
//  LocationService.swift
//  RxPlayground
//
//  Created by Choi on 2021/4/23.
//

import Foundation
import RxSwift
import RxCocoa
import CoreLocation

extension CLLocationManager: HasDelegate {
	public typealias Delegate = CLLocationManagerDelegate
}

// MARK: - __________ 代理对象 __________
public class RxCLLocationManagerDelegateProxy:
	DelegateProxy<CLLocationManager, CLLocationManagerDelegate>,
	DelegateProxyType, CLLocationManagerDelegate {

	public init(locationManager: CLLocationManager) {
		super.init(parentObject: locationManager, delegateProxy: RxCLLocationManagerDelegateProxy.self)
	}
	public static func registerKnownImplementations() {
		register { RxCLLocationManagerDelegateProxy(locationManager: $0) }
	}

	// MARK: - __________ 订阅Subject __________
	internal lazy var didUpdateLocationsSubject = PublishSubject<[CLLocation]>()
	internal lazy var didFailWithErrorSubject = PublishSubject<Error>()
	
	// MARK: - __________ 定位代理实现 __________
	public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		_forwardToDelegate?.locationManager(manager, didUpdateLocations: locations)
		didUpdateLocationsSubject.onNext(locations)
	}
	public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		_forwardToDelegate?.locationManager(manager, didFailWithError: error)
		didFailWithErrorSubject.onNext(error)
	}
	// MARK: - __________ 回收♻️处理 __________
	deinit {
		didUpdateLocationsSubject.on(.completed)
		didFailWithErrorSubject.on(.completed)
	}
}
// MARK: - __________ 封装 __________
extension Reactive where Base: CLLocationManager {
	
	public var delegate: RxCLLocationManagerDelegateProxy {
		RxCLLocationManagerDelegateProxy.proxy(for: base)
	}
	public var didUpdateLocations: Observable<[CLLocation]> {
		delegate.didUpdateLocationsSubject.asObservable()
	}
	public var didFailWithError: Observable<Error> {
		delegate.didFailWithErrorSubject.asObservable()
	}
	#if os(iOS) || os(macOS)
	/**
	Reactive wrapper for `delegate` message.
	*/
	public var didFinishDeferredUpdatesWithError: Observable<Error?> {
		delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didFinishDeferredUpdatesWithError:)))
			.map { a in
				try castOptionalOrThrow(Error.self, a[1])
			}
	}
	#endif

	#if os(iOS)

	// MARK: Pausing Location Updates

	/**
	Reactive wrapper for `delegate` message.
	*/
	public var didPauseLocationUpdates: Observable<Void> {
		delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManagerDidPauseLocationUpdates(_:)))
			.map { _ in
				return ()
			}
	}

	/**
	Reactive wrapper for `delegate` message.
	*/
	public var didResumeLocationUpdates: Observable<Void> {
		delegate.methodInvoked( #selector(CLLocationManagerDelegate.locationManagerDidResumeLocationUpdates(_:)))
			.map { _ in
				return ()
			}
	}

	// MARK: Responding to Heading Events

	/**
	Reactive wrapper for `delegate` message.
	*/
	public var didUpdateHeading: Observable<CLHeading> {
		delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didUpdateHeading:)))
			.map { a in
				try castOrThrow(CLHeading.self, a[1])
			}
	}

	// MARK: Responding to Region Events

	/**
	Reactive wrapper for `delegate` message.
	*/
	public var didEnterRegion: Observable<CLRegion> {
		delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didEnterRegion:)))
			.map { a in
				try castOrThrow(CLRegion.self, a[1])
			}
	}

	/**
	Reactive wrapper for `delegate` message.
	*/
	public var didExitRegion: Observable<CLRegion> {
		delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didExitRegion:)))
			.map { a in
				try castOrThrow(CLRegion.self, a[1])
			}
	}

	#endif

	#if os(iOS) || os(macOS)

	/**
	Reactive wrapper for `delegate` message.
	*/
	@available(OSX 10.10, *)
	public var didDetermineStateForRegion: Observable<(state: CLRegionState, region: CLRegion)> {
		delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didDetermineState:for:)))
			.map { a in
				let stateNumber = try castOrThrow(NSNumber.self, a[1])
				let state = CLRegionState(rawValue: stateNumber.intValue) ?? CLRegionState.unknown
				let region = try castOrThrow(CLRegion.self, a[2])
				return (state: state, region: region)
			}
	}

	/**
	Reactive wrapper for `delegate` message.
	*/
	public var monitoringDidFailForRegionWithError:
		Observable<(region: CLRegion?, error: Error)> {
		delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:monitoringDidFailFor:withError:)))
			.map { a in
				let region = try castOptionalOrThrow(CLRegion.self, a[1])
				let error = try castOrThrow(Error.self, a[2])
				return (region: region, error: error)
			}
	}

	/**
	Reactive wrapper for `delegate` message.
	*/
	public var didStartMonitoringForRegion: Observable<CLRegion> {
		delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didStartMonitoringFor:)))
			.map { a in
				try castOrThrow(CLRegion.self, a[1])
			}
	}

	#endif

	#if os(iOS)

	// MARK: Responding to Ranging Events

	/**
	Reactive wrapper for `delegate` message.
	*/
	public var didRangeBeaconsInRegion: Observable<(beacons: [CLBeacon],
													region: CLBeaconRegion)> {
		if #available(iOS 13.0, *) {
			return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didRange:satisfying:)))
				.map { a in
					let id = UUID()
					let beacons = try castOrThrow([CLBeacon].self, a[1])
					let constraint = try castOrThrow(CLBeaconIdentityConstraint.self, a[2])
					let region = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: id.uuidString)
					return (beacons: beacons, region: region)
				}
		} else {
			return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didRangeBeacons:in:)))
				.map { a in
					let beacons = try castOrThrow([CLBeacon].self, a[1])
					let region = try castOrThrow(CLBeaconRegion.self, a[2])
					return (beacons: beacons, region: region)
				}
		}
	}

	/**
	Reactive wrapper for `delegate` message.
	*/
	public var rangingBeaconsDidFailForRegionWithError:
		Observable<(region: CLBeaconRegion, error: Error)> {
		if #available(iOS 13, *) {
			return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didFailRangingFor:error:)))
				.map { a in
					let id = UUID()
					let constraint = try castOrThrow(CLBeaconIdentityConstraint.self, a[1])
					let region = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: id.uuidString)
					let error = try castOrThrow(Error.self, a[2])
					return (region: region, error: error)
				}
		} else {
			return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:rangingBeaconsDidFailFor:withError:)))
				.map { a in
					let region = try castOrThrow(CLBeaconRegion.self, a[1])
					let error = try castOrThrow(Error.self, a[2])
					return (region: region, error: error)
				}
		}
	}

	// MARK: Responding to Visit Events

	/**
	Reactive wrapper for `delegate` message.
	*/
	@available(iOS 8.0, *)
	public var didVisit: Observable<CLVisit> {
		delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didVisit:)))
			.map { a in
				try castOrThrow(CLVisit.self, a[1])
			}
	}

	#endif

	// MARK: Responding to Authorization Changes

	/**
	Reactive wrapper for `delegate` message.
	*/
	public var didChangeAuthorizationStatus: Observable<CLAuthorizationStatus> {
		if #available(iOS 14, *) {
			return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManagerDidChangeAuthorization(_:)))
				.map { args in
					try castOrThrow(CLLocationManager.self, args[0]).authorizationStatus
				}
		} else {
			return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didChangeAuthorization:)))
				.map { a in
					let raw = try castOrThrow(NSNumber.self, a[1])
					return CLAuthorizationStatus(rawValue: raw.int32Value) ?? .notDetermined
				}
		}
	}
}

fileprivate func castOrThrow<T>(_ resultType: T.Type, _ object: Any) throws -> T {
	guard let returnValue = object as? T else {
		throw RxCocoaError.castingError(object: object, targetType: resultType)
	}
	return returnValue
}

fileprivate func castOptionalOrThrow<T>(_ resultType: T.Type,
										_ object: Any) throws -> T? {
	if NSNull().isEqual(object) {
		return nil
	}
	guard let returnValue = object as? T else {
		throw RxCocoaError.castingError(object: object, targetType: resultType)
	}

	return returnValue
}

extension CLAuthorizationStatus {
	var canLocate: Bool {
		3...4 ~= rawValue
	}
}

class GeolocationService {
	
	/// 单例
	static let instance = GeolocationService()
	
	/// 核心对象
	private let locationManager: CLLocationManager = {
		let mgr = CLLocationManager()
		mgr.distanceFilter = kCLDistanceFilterNone
		mgr.desiredAccuracy = kCLLocationAccuracyBestForNavigation
		return mgr
	}()
	
	let authorized: Driver<Bool>
	let authorizationStatus: Observable<CLAuthorizationStatus>
	let location: Driver<CLLocationCoordinate2D>
	
	private init() {
		
		let status = locationManager.rx.didChangeAuthorizationStatus
			.startWith(locationManager.authorizationStatus)
			.distinctUntilChanged()
		
		authorizationStatus = status
		authorized = status
			.map(\.canLocate)
			.asDriver(onErrorJustReturn: false)
		
		location = locationManager.rx.didUpdateLocations
			.asDriver(onErrorJustReturn: [])
			.compactMap(\.last)
			.map(\.coordinate)
		// 请求权限
		locationManager.requestAlwaysAuthorization()
		// 开始更新位置
		locationManager.startUpdatingLocation()
	}
}
