const state = {};

export function create_with_unique_name(name, init) {
  if (!state.hasOwnProperty(name)) {
    state[name] = init();
  }
  return state[name];
}
