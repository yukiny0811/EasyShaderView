//
//  CameraType.swift
//  ShaderView
//
//  Created by Yuki Kuwashima on 2025/02/17.
//

/// An enumeration representing the available camera control types.
///
/// Currently, it includes:
/// - `orbit`: A camera mode where the camera orbits around a target point.
public enum CameraType {
    /// Orbit mode: the camera rotates around a target while maintaining a fixed distance.
    case orbit

    case manual
}
