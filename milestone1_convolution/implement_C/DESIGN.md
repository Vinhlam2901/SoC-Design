# Implementation C — one-multiplier baseline

Thiết kế hỗ trợ valid 3×3, stride 1, không padding. Pixel unsigned 8-bit, coefficient signed 8-bit, accumulator/output signed 32-bit. Không đảo kernel, normalize, abs hoặc clamp. Mặc định kích thước input từ 3×3 đến 16×16, có thể đổi MAX_WIDTH/MAX_HEIGHT tại instance convolution.

## Hierarchy và dữ liệu

```text
single_cycle → lsu → convolution → mac → mul → booth_encoder/csa/cla_nbit
                  ├ image_mem: 256 × 8-bit
                  ├ kernel_mem: 9 × 8-bit
                  └ output_mem: 196 × signed 32-bit
```

Chỉ có một instance `mul` trong đường tính convolution. Module MAC cũ dùng input vector chín tap và pipeline cộng đã được thay bằng MAC tuần tự nhận một cặp toán hạng mỗi lần enable. Bỏ phụ thuộc window_generator và các typedef pipeline cũ. WIDTH_MAC trong package đổi thành 32. WIDTH/LENGTH 256 trong package là giá trị cũ, không điều khiển dung lượng IP mới; dùng MAX_WIDTH/MAX_HEIGHT của convolution.

`mac_clear_i` xóa accumulator trước output mới. `mac_en_i` cộng product đã sign-extend vào accumulator. Không cần valid pipeline: FSMD biết chính xác cạnh clock clear/read/accumulate/write.

## MMIO

LSU decode toàn địa chỉ trang 0x40000000 và chỉ chuyển giao dịch LW/SW đúng địa chỉ sang IP. GPIO/LED và DMEM 2 KiB vẫn thuộc LSU. Các trường MUL_* không sử dụng và trả 0 trong bản C; chỉ dùng giao diện CONV_*. Register bank convolution thuộc IP, không lưu trùng trong LSU.

| Address | Register | Access / behavior |
|---|---|---|
| 0x40000200 | CONV_CTRL | RW, bit 0 START; các bit khác bằng 0 |
| 0x40000204 | CONV_STATUS | RO, bit 0 BUSY, bit 1 DONE |
| 0x40000208 | IMG_WIDTH | RW, chiều rộng input |
| 0x4000020c | IMG_HEIGHT | RW, chiều cao input |
| 0x40000210 | IMG_ADDR | RW, index pixel theo row-major |
| 0x40000214 | IMG_DATA | RW, low 8 bits truy cập image_mem[IMG_ADDR] |
| 0x40000218 | KER_ADDR | RW, index 0..8 |
| 0x4000021c | KER_DATA | RW, low 8 bits truy cập kernel_mem[KER_ADDR] |
| 0x40000220 | OUT_ADDR | RW, index output theo row-major |
| 0x40000224 | OUT_DATA | RO, signed 32-bit output_mem[OUT_ADDR] |

DATA readback ảnh/kernel zero-extend low 8 bits; sign của kernel được xử lý tại MAC. ADDR dùng index phần tử, không phải byte address DMEM. Không tự tăng index. IMG_ADDR/KER_ADDR ngoài vùng: ghi DATA bị bỏ qua, đọc DATA trả 0, không truncate địa chỉ gây alias. OUT_ADDR ngoài dung lượng: đọc trả 0. Chỉ đọc output thuộc tác vụ hiện tại sau DONE; phần tử chưa được ghi không có giá trị xác định.

Mỗi SW START=1 là một yêu cầu, không cần SW=0 xen giữa. IP chỉ nhận khi IDLE và 3≤W≤MAX_WIDTH, 3≤H≤MAX_HEIGHT. Cấu hình không hợp lệ: bỏ qua START, BUSY/DONE giữ nguyên. Khi nhận tác vụ mới: chốt W/H, BUSY=1, DONE=0. Output cuối ghi xong thì BUSY=0, DONE=1. DONE giữ đến START hợp lệ hoặc reset; SW CTRL=0 không hủy tác vụ. START và ghi cấu hình/ảnh/kernel trong BUSY bị bỏ qua. OUT_ADDR vẫn ghi được lúc BUSY; phần mềm nên chờ DONE rồi đọc output.

## FSMD

```text
IDLE --valid START--> CLEAR_ACC → READ_TAP → ACCUMULATE
                                      ↑        │
                                      └─tap<8──┘
                            tap=8 → WRITE_OUT
                                      ├─more outputs → CLEAR_ACC
                                      └─last output → IDLE, DONE=1
```

READ_TAP đọc đồng bộ một pixel và một coefficient. ACCUMULATE dùng dữ liệu của bước đọc trước. WRITE_OUT là chu kỳ riêng sau tap cuối, nên không mất product thứ 9 do nonblocking assignment.

`row_base` giữ đầu hàng output trong ảnh input. `tap_row_base` tăng thêm W khi chuyển hàng kernel, địa chỉ pixel là tap_row_base+kernel_col. Các địa chỉ được sinh bằng phép cộng/counter, không thêm multiplier tính địa chỉ. Các tín hiệu `state`, `out_row`, `out_col`, `tap_index`, `kernel_row/col`, `accumulator`, `busy`, `done` có thể xem trong waveform.

FSMD hiện tại dùng 20 chu kỳ cho mỗi output tính từ cạnh nhận START đến cạnh ghi output cuối: 1 CLEAR + 9×(READ+MAC) + 1 WRITE. Đây là độ trễ tính toán của IP, chưa bao gồm CPU nạp/đọc dữ liệu. Clock period phải đáp ứng đường multiplier + adder trong chu kỳ MAC.

Memory arrays không reset toàn bộ. CPU phải nạp đủ ảnh/kernel trước START. Reset giữa tác vụ hủy tác vụ, xóa config/status/control; không xóa nội dung memory. Đọc MMIO DATA là tổ hợp để CPU giữ load một chu kỳ. Việc infer RAM/block RAM phụ thuộc synthesis flow và port đọc, chưa được xác nhận synthesis.

## Kiểm tra

Từ 02_sim với Xcelium/license đã cấu hình:

```sh
make cpu IMPLEMENT=C
make conv IMPLEMENT=C
```

Có thể truyền XRUN là đường dẫn tool. CPU regression PASS 153 kiểm tra, gồm một convolution 3×3 có output −27 đi qua CPU load và store DMEM. MMIO/accelerator regression PASS 11 tác vụ, 1.177 output: ảnh 3×3, 4×4, 8×8, 16×16, 8×16; ảnh ngẫu nhiên xác định bằng seed; kernel tổng blur, sharpen, edge bất đối xứng, −128 và +127. Kiểm tra repeated START, DONE cũ, ghi khi BUSY, readback storage/config, register RO, địa chỉ không hợp lệ và reset giữa tác vụ.

Golden hiện là phép tính độc lập trong testbench, chưa đối chiếu đầy đủ với baseline assembly A. Chưa có ứng dụng assembly convolution toàn ảnh, báo cáo tài nguyên/timing hoặc đo end-to-end để hoàn tất milestone. Không có thay đổi RTL A/B trong lượt này.
