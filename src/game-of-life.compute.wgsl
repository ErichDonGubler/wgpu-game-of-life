@binding(0) @group(0) var<storage, read> current: array<u32>;
@binding(1) @group(0) var<storage, read_write> next: array<u32>;
@binding(2) @group(0) var<uniform> size: vec2<u32>;
@binding(3) @group(0) var<uniform> rule: vec2<i32>;

const TILE: u32 = 16u;
const TILE_PAD: u32 = 18u;
const TILE_PAD_AREA: u32 = 324u;
const THREADS_PER_GROUP: u32 = 256u;

var<workgroup> tile: array<u32, TILE_PAD_AREA>;

fn wrap(coord: i32, dim: i32) -> i32 {
    let m = coord % dim;
    return m + select(0, dim, m < 0);
}

@compute @workgroup_size(16, 16)
fn main(
    @builtin(global_invocation_id) gid: vec3<u32>,
    @builtin(local_invocation_id) lid: vec3<u32>,
) {
    let w = i32(size.x);
    let h = i32(size.y);
    let tile_origin_x = i32(gid.x) - i32(lid.x) - 1;
    let tile_origin_y = i32(gid.y) - i32(lid.y) - 1;

    let local_index = lid.y * TILE + lid.x;
    for (var i = local_index; i < TILE_PAD_AREA; i = i + THREADS_PER_GROUP) {
        let lx = i % TILE_PAD;
        let ly = i / TILE_PAD;
        let gx = wrap(tile_origin_x + i32(lx), w);
        let gy = wrap(tile_origin_y + i32(ly), h);
        tile[i] = current[u32(gy * w + gx)];
    }

    workgroupBarrier();

    let cx = lid.x + 1u;
    let cy = lid.y + 1u;
    let top = (cy - 1u) * TILE_PAD;
    let mid = cy * TILE_PAD;
    let bot = (cy + 1u) * TILE_PAD;

    let n =
        u32(tile[top + cx - 1u] > 0u) +
        u32(tile[top + cx]       > 0u) +
        u32(tile[top + cx + 1u] > 0u) +
        u32(tile[mid + cx - 1u] > 0u) +
        u32(tile[mid + cx + 1u] > 0u) +
        u32(tile[bot + cx - 1u] > 0u) +
        u32(tile[bot + cx]       > 0u) +
        u32(tile[bot + cx + 1u] > 0u);

    let current_generation = tile[mid + cx];
    let cell_lives = current_generation >= 1u;
    let will_be_born = u32(((1u << n) & u32(rule.x)) > 0u);
    let will_survive = u32(((1u << n) & u32(rule.y)) > 0u) * (1u + current_generation);
    next[gid.y * size.x + gid.x] = select(will_be_born, will_survive, cell_lives);
}
