use winit::{
    event::{ElementState, Event, KeyboardInput, VirtualKeyCode, WindowEvent},
    event_loop::ControlFlow,
};

use crate::State;

pub fn handle_event_loop(event: &Event<()>, state: &mut State, control_flow: &mut ControlFlow) {
    // *control_flow = ControlFlow::WaitUntil(Instant::now().add(Duration::from_millis(1000)));
    match event {
        &Event::WindowEvent {
            ref event,
            window_id,
        } if window_id == state.window.id() => {
            if !state.input(event) {
                match event {
                    WindowEvent::CloseRequested
                    | WindowEvent::KeyboardInput {
                        input:
                            KeyboardInput {
                                state: ElementState::Pressed,
                                virtual_keycode: Some(VirtualKeyCode::Escape),
                                ..
                            },
                        ..
                    } => *control_flow = ControlFlow::Exit,
                    WindowEvent::KeyboardInput {
                        input:
                            KeyboardInput {
                                state: ElementState::Pressed,
                                virtual_keycode: Some(VirtualKeyCode::Space),
                                ..
                            },
                        ..
                    } => {
                        println!("Space press");
                        state.window.set_title("SPACE");
                    }
                    WindowEvent::Resized(physical_size) => {
                        state.resize(*physical_size);
                    }
                    WindowEvent::ScaleFactorChanged { new_inner_size, .. } => {
                        state.resize(**new_inner_size);
                    }
                    _ => {}
                }
            }
        }

        &Event::RedrawRequested(window_id) if window_id == state.window.id() => {
            state.update();
            match state.render() {
                Ok(_) => {}
                // Reconfigure the surface if lost
                Err(wgpu::SurfaceError::Lost) => state.resize(state.size),
                // The system is out of memory, we should probably quit
                Err(wgpu::SurfaceError::OutOfMemory) => *control_flow = ControlFlow::Exit,
                // All other errors (Outdated, Timeout) should be resolved by the next frame
                Err(e) => eprintln!("{:?}", e),
            }
        }
        //Event::NewEvents(StartCause::Init) => {
        // From the winit README:
        // "A lot of functionality expects the application to be ready before you start doing anything;
        // this includes creating windows, fetching monitors, drawing, and so on, see issues #2238, #2051
        // and #2087.
        // If you encounter problems, you should try doing your initialization inside
        // Event::NewEvents(StartCause::Init)."
        //state .window .set_fullscreen(Some(winit::window::Fullscreen::Borderless(None)));
        //state.window.focus_window();
        //}
        Event::MainEventsCleared => {
            state.window.request_redraw();
        }
        _ => {}
    }
}
