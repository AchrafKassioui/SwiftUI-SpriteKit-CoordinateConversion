//
//  CoordinateConversion
//
//		Original boilerplate by John Knowles https://gist.github.com/overlair/b500460a3190d608d7d2a8108c8c0d0c
//  Forked by Achraf Kassioui on 30 October 2023
//

/*
	
	Questions:
	- Geometry Reader: what is it for?
	- There's an enum ControlUpdate with 3 cases, then there's a handle
	
	*/

import SpriteKit
import SwiftUI
import Combine

enum ControlUpdate {
				case tap(UITapGestureRecognizer) // print SpriteKit coordinate
				case doubleTap // reset camera
				case pan(UIPanGestureRecognizer) // move camera
}

// MARK: - SwiftUI view

struct ExampleView: View {
				@State var isPaused = false
				
				var messages = PassthroughSubject<ControlUpdate, Never>()
				
				var body: some View {
								GeometryReader { geo in
												SpriteKitView(isPaused: $isPaused,
																										size: geo.size,
																										messages: messages)
												.overlay(gestures)
								}
								.ignoresSafeArea()
				}
				
				@ViewBuilder var gestures: some View {
								ExampleGestureRepresentable(messages: messages)
												.frame(maxWidth: .infinity, maxHeight: .infinity)
				}
}

// MARK: - What is this?

struct SpriteKitView: View {
				@Binding var isPaused: Bool
				
				let size: CGSize
				let messages: PassthroughSubject<ControlUpdate, Never>
				
				var scene: SKScene{
								let scene = ExampleScene(size: size, messages: messages)
								scene.size = size
								scene.scaleMode = .fill
								return scene
				}
				
				var body: some View {
								SpriteView(scene: scene,
																			isPaused: isPaused)
								.frame(width: size.width, height: size.height)
				}
}

struct ExampleGestureRepresentable: UIViewRepresentable {
				let messages:  PassthroughSubject<ControlUpdate, Never>
				
				func makeUIView(context: Context) -> some UIView {
								let v = UIView(frame: .zero)
								
								let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tap))
								v.addGestureRecognizer(tap)
								
								let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.pan))
								v.addGestureRecognizer(pan)
								
								let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.doubleTap))
								doubleTap.numberOfTapsRequired = 2
								v.addGestureRecognizer(doubleTap)
								
								return v
				}
				
				class Coordinator: NSObject, UIGestureRecognizerDelegate {
								let messages:  PassthroughSubject<ControlUpdate, Never>
								
								init(messages: PassthroughSubject<ControlUpdate, Never>) {
												self.messages = messages
								}
								
								@objc func tap(gesture: UITapGestureRecognizer) {
												messages.send(.tap(gesture))
								}
								
								@objc func doubleTap(gesture: UITapGestureRecognizer) {
												messages.send(.doubleTap)
								}
								
								
								@objc func pan(gesture: UIPanGestureRecognizer) {
												messages.send(.pan(gesture))
								}
				}
				
				func makeCoordinator() -> Coordinator {
								Coordinator(messages: messages)
				}
				
				func updateUIView(_ uiView: UIViewType, context: Context) {}
}

class ExampleScene: SKScene {
				let messages:  PassthroughSubject<ControlUpdate, Never>
				
				init(size: CGSize,
									messages: PassthroughSubject<ControlUpdate, Never>) {
								self.messages = messages
								
								super.init(size: size)
				}
				
				required init?(coder aDecoder: NSCoder) {
								fatalError("init(coder:) has not been implemented")
				}
				
				override func sceneDidLoad() {
								super.sceneDidLoad()
								setup()
				}
				
				var cancellables = Set<AnyCancellable>()
				
				private func  setup() {
								messages
												.sink(receiveValue: handle)
												.store(in: &cancellables)
								
								// setup nodes
								
								let shape: CGPath = .init(roundedRect: .init(origin: .zero,
																																																					size: .init(width: 50,height: 50)),
																																		cornerWidth: 12,
																																		cornerHeight: 12,
																																		transform: nil)
								
								
								
								let tapNode = SKShapeNode(path: shape, centered: true)
								self.shapeNode = tapNode
								self.shapeNode?.position = origin
								self.shapeNode?.fillColor = .blue
								addChild(tapNode)
								
								let node = SKShapeNode(path: shape, centered: true)
								node.position = origin
								node.fillColor = .orange
								addChild(node)
								
								
								camera = sceneCamera
								sceneCamera.position = origin
								addChild(sceneCamera)
				}
				
				var sceneCamera: SKCameraNode = SKCameraNode()
				var shapeNode: SKShapeNode? = nil
				
				var origin: CGPoint {
								CGPoint(x: size.width / 2.0, y: size.height / 2.0)
				}
				
				var dragOrigin: CGPoint = .zero
				
				// MARK: - Handle
				
				private func handle(_ message: ControlUpdate) {
								switch message {
								case .tap(let gesture):
												let location = gesture.location(in: gesture.view)
												let point = convertPoint(fromView: location)
												
												moveNode(node: shapeNode,
																					to: point,
																					at: 0.3,
																					with: .easeOut)
												
								case .pan(let  pan):
												switch pan.state {
												case .began:
																dragOrigin = self.camera?.position ?? .zero
												case .changed:
																let translation = pan.translation(in: pan.view)
																let point =  CGPoint(x: dragOrigin.x - translation.x,
																																					y: dragOrigin.y + translation.y)
																
																moveNode(node: sceneCamera,
																									to: point)
												case .ended, .cancelled:
																dragOrigin = .zero
																
												default: break
												}
												break
												
								case .doubleTap:
												moveNode(node: sceneCamera,
																					to: origin,
																					at: 0.3,
																					with: .easeInEaseOut)
												break
								}
				}
				
				func moveNode(node: SKNode?,
																		to point: CGPoint,
																		at  duration: CGFloat = 0.0,
																		with timing: SKActionTimingMode = .linear) {
								let move = SKAction.move(to: point, duration: duration)
								move.timingMode = timing
								
								node?.run(move, withKey: "moveNode")
				}
}

struct ContentView_Previews: PreviewProvider {
				static var previews: some View {
								ExampleView()
				}
}
