//
//  CameraConfiguration.swift
//  ShaderView
//
//  Created by Yuki Kuwashima on 2025/02/17.
//

/**
 A configuration structure for 3D rendering parameters.

 This structure holds options for controlling the 3D environment, including the camera control type and a
 scaling factor for 3D models.
 */
public struct CameraConfiguration {
    /// The type of camera control to use. Default is `.orbit`, which allows the camera to orbit around a target point.
    public var cameraType: CameraType = .orbit

    /// A scaling factor applied to 3D models. A value of 1 indicates no scaling.
    public var scaleFactor: Float = 1

    public init(cameraType: CameraType, scaleFactor: Float) {
        self.cameraType = cameraType
        self.scaleFactor = scaleFactor
    }
}
