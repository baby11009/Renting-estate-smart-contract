// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HopDongThueCanHo {
    struct ThongTinNha {
        address chuNha;
        uint256 chiPhiHangThang;
        uint256 thoiGianThueThang;
        bool hopDongDuocKy;
    }

    struct ThongTinThue {
        address nguoiThue;
        uint256 thoiDiemBatDau;
        uint256 soThangDaThanhToan;
        uint256 thoiDiemKetThuc;
    }

    struct DeNghiGiaHan {
        uint256 soThangThem;
        uint256 soTienDaChuyen;
    }

    ThongTinNha public thongTinNha;
    ThongTinThue private thongTinThue;
    DeNghiGiaHan private deNghiGiaHan;
    mapping(address => uint256) private soDuTaiKhoan;

    constructor(uint256 _chiPhiHangThang, uint256 _thoiGianThueThang) {
        require(_chiPhiHangThang > 0, "Chi phi hang thang phai > 0");
        require(_thoiGianThueThang > 0, "Thoi gian thue phai > 0");

        thongTinNha.chuNha = msg.sender;
        thongTinNha.chiPhiHangThang = _chiPhiHangThang;
        thongTinNha.thoiGianThueThang = _thoiGianThueThang;
        thongTinNha.hopDongDuocKy = false;
    }

    function xemTinhTrangThue()
        external
        view
        returns (
            address nguoiThue,
            uint256 thoiDiemBatDau,
            uint256 soThangDaThanhToan,
            uint256 thoiGianConLai
        )
    {
        if (
            thongTinThue.nguoiThue == address(0) ||
            (msg.sender != thongTinNha.chuNha &&
                msg.sender != thongTinThue.nguoiThue)
        ) {
            return (
                address(0),
                thongTinThue.thoiDiemBatDau,
                thongTinThue.soThangDaThanhToan,
                0
            );
        }

        uint256 thoiGianConLaiTinh = 0;
        if (block.timestamp < thongTinThue.thoiDiemKetThuc) {
            thoiGianConLaiTinh =
                (thongTinThue.thoiDiemKetThuc - block.timestamp) /
                30 seconds;
        }

        return (
            thongTinThue.nguoiThue,
            thongTinThue.thoiDiemBatDau,
            thongTinThue.soThangDaThanhToan,
            thoiGianConLaiTinh
        );
    }

    function kyHopDong() external payable {
        require(!thongTinNha.hopDongDuocKy, "Hop dong da duoc ky");
        require(msg.sender != thongTinNha.chuNha, "Chu nha khong the tu ky");
        require(
            msg.value >=
                thongTinNha.chiPhiHangThang * thongTinNha.thoiGianThueThang,
            "Phai nap du tien cho toan bo ky han"
        );

        thongTinThue.nguoiThue = msg.sender;
        thongTinThue.thoiDiemBatDau = block.timestamp;
        thongTinThue.soThangDaThanhToan = 0;
        thongTinThue.thoiDiemKetThuc =
            block.timestamp +
            thongTinNha.thoiGianThueThang *
            30 seconds;

        soDuTaiKhoan[thongTinThue.nguoiThue] = msg.value;
        thongTinNha.hopDongDuocKy = true;
    }

    function rutTien(uint256 soThangMuonRut) external payable {
        require(
            msg.sender == thongTinNha.chuNha,
            "Chi chu nha moi duoc rut tien"
        );
        require(thongTinNha.hopDongDuocKy, "Chua co hop dong hop le");
        require(
            thongTinThue.soThangDaThanhToan < thongTinNha.thoiGianThueThang,
            "Nguoi thue da thanh toan day du"
        );

        uint256 soThangDaThue = (block.timestamp -
            thongTinThue.thoiDiemBatDau) / 30 seconds;

        uint256 soThangChoRut = soThangDaThue;

        require(
            soThangChoRut >= soThangMuonRut,
            "Chua co thang nao moi de rut"
        );

        require(
            thongTinNha.thoiGianThueThang - thongTinThue.soThangDaThanhToan >=
                soThangMuonRut,
            "So thang muon rut lon hon so thoi gian con lai"
        );

        uint256 soTienRut = soThangMuonRut * thongTinNha.chiPhiHangThang;

        soDuTaiKhoan[thongTinThue.nguoiThue] -= soTienRut;

        thongTinThue.soThangDaThanhToan += soThangMuonRut;
        (bool success, ) = payable(thongTinNha.chuNha).call{value: soTienRut}(
            ""
        );

        require(success, "Chuyen tien that bai");
    }

    function xemSoDu(address taiKhoan) external view returns (uint256) {
        require(
            msg.sender == thongTinThue.nguoiThue ||
                msg.sender == thongTinNha.chuNha,
            "Chi nguoi thue hoac chu nha moi duoc xem so du"
        );

        return soDuTaiKhoan[taiKhoan];
    }

    function rutSoDu(uint256 soTienCanRut) external payable {
        require(
            msg.sender == thongTinThue.nguoiThue,
            "Chi nguoi thue moi duoc rut so du"
        );
        require(soTienCanRut > 0, "So tien can rut > 0");

        uint256 soTienDuocRut = soDuTaiKhoan[msg.sender];
        uint256 soTienChuaThanhToan = (thongTinNha.thoiGianThueThang -
            thongTinThue.soThangDaThanhToan) * thongTinNha.chiPhiHangThang;
        soTienDuocRut = soTienDuocRut - soTienChuaThanhToan;
        if (
            deNghiGiaHan.soTienDaChuyen > 0 &&
            deNghiGiaHan.soThangThem * thongTinNha.chiPhiHangThang <
            deNghiGiaHan.soTienDaChuyen
        ) {
            uint256 soTienCanPhaiBu = deNghiGiaHan.soThangThem *
                thongTinNha.chiPhiHangThang -
                deNghiGiaHan.soTienDaChuyen;

            soTienDuocRut = soTienDuocRut - soTienCanPhaiBu;

            deNghiGiaHan.soTienDaChuyen += soTienCanPhaiBu;
        }
        require(soTienDuocRut >= soTienCanRut, "So du khong du de thuc hien");

        (bool success, ) = payable(msg.sender).call{value: soTienDuocRut}("");
        require(success, "Chuyen tien that bai");
        soDuTaiKhoan[thongTinThue.nguoiThue] = soTienChuaThanhToan;
    }

    function yeuCauGiaHan(uint256 soThangThem) external payable {
        require(thongTinNha.hopDongDuocKy, "Chua co hop dong");
        require(
            msg.sender == thongTinThue.nguoiThue,
            "Chi nguoi thue moi duoc gia han"
        );
        // Giới hạn thời gian gia hạn: chỉ được phép gia hạn trong vòng 5s sau khi hết hạn
        require(
            block.timestamp <= thongTinThue.thoiDiemKetThuc + 15 seconds,
            "Da qua thoi gian cho phep gia han"
        );

        require(soThangThem > 0, "Phai them it nhat 1 thang");

        require(
            soDuTaiKhoan[msg.sender] + msg.value >=
                (soThangThem +
                    thongTinNha.thoiGianThueThang -
                    thongTinThue.soThangDaThanhToan) *
                    thongTinNha.chiPhiHangThang,
            "So du con lai khong du de gia han"
        );

        deNghiGiaHan = DeNghiGiaHan({
            soThangThem: soThangThem,
            soTienDaChuyen: msg.value
        });
    }

    function xemYeuCauGiaHanHopDong()
        external
        view
        returns (uint256 soThangThem, uint256 soTienDaChuyen)
    {
        require(thongTinNha.hopDongDuocKy, "Chua co hop dong");
        require(
            msg.sender == thongTinThue.nguoiThue ||
                msg.sender == thongTinNha.chuNha,
            "Chi nguoi thue hoac chu nha moi duoc xem yeu cau gia han"
        );
        require(deNghiGiaHan.soThangThem > 0, "Chua co yeu cau gia han");

        return (deNghiGiaHan.soThangThem, deNghiGiaHan.soTienDaChuyen);
    }

    function chapNhanYeuCauGiaHan() external {
        require(thongTinNha.hopDongDuocKy, "Chua co hop dong");
        require(
            msg.sender == thongTinNha.chuNha,
            "Chi chu nha moi duoc chap nhan gia han"
        );
        require(deNghiGiaHan.soThangThem > 0, "Chua co yeu cau gia han");

        // Gia hạn thời gian kết thúc hợp đồng
        thongTinThue.thoiDiemKetThuc += deNghiGiaHan.soThangThem *30 seconds;

        // Cập nhật tổng số tháng trong hợp đồng
        thongTinNha.thoiGianThueThang += deNghiGiaHan.soThangThem;

        // Cập nhật số dư tài khoản
        soDuTaiKhoan[thongTinThue.nguoiThue] += deNghiGiaHan.soTienDaChuyen;

        delete deNghiGiaHan;
    }

    function huyYeuCauGiaHan() external payable {
        require(thongTinNha.hopDongDuocKy, "Chua co hop dong");
        require(
            msg.sender == thongTinNha.chuNha ||
                msg.sender == thongTinThue.nguoiThue,
            "Chi chu nha hoac nguoi thue moi duoc huy gia han"
        );
        require(deNghiGiaHan.soThangThem > 0, "Chua co yeu cau gia han");
        (bool success, ) = payable(msg.sender).call{
            value: deNghiGiaHan.soTienDaChuyen
        }("");
        require(success, "Hoan tien that bai");
        delete deNghiGiaHan;
    }

    function chamDutHopDong() external payable {
        require(thongTinNha.hopDongDuocKy, "Chua co hop dong");
        require(
            msg.sender == thongTinThue.nguoiThue ||
                msg.sender == thongTinNha.chuNha,
            "Chi chu nha hoac nguoi thue moi co quyen"
        );

        if (soDuTaiKhoan[thongTinThue.nguoiThue] > 0) {
            uint256 tongThangThue = thongTinNha.thoiGianThueThang;
            uint256 soThangDaSuDung = (block.timestamp -
                thongTinThue.thoiDiemBatDau) / 30 seconds;

            if (soThangDaSuDung > tongThangThue) {
                soThangDaSuDung = tongThangThue;
            }

            uint256 soTienChuaThanhToan = (soThangDaSuDung -
                thongTinThue.soThangDaThanhToan) * thongTinNha.chiPhiHangThang;

            uint256 tienHoanLai = soDuTaiKhoan[thongTinThue.nguoiThue] -
                soTienChuaThanhToan;

            // Nếu có tiền hoàn lại, thực hiện chuyển tiền
            if (tienHoanLai > 0) {
                (bool success, ) = payable(msg.sender).call{value: tienHoanLai}(
                    ""
                );
                require(success, "Chuyen tien that bai");
            }

            // CHuyển số tiền chưa thanh toán cho chủ nhà
            if (soTienChuaThanhToan > 0) {
                (bool success, ) = payable(msg.sender).call{
                    value: soTienChuaThanhToan
                }("");
                require(success, "Chuyen tien that bai");
            }

            soDuTaiKhoan[thongTinThue.nguoiThue] = 0;
        }

        // Chấm dứt hợp đồng
        thongTinNha.hopDongDuocKy = false;

        // Reset thông tin người thuê
        thongTinThue.nguoiThue = address(0);
        thongTinThue.thoiDiemBatDau = 0;
        thongTinThue.soThangDaThanhToan = 0;
        thongTinThue.thoiDiemKetThuc = 0;
    }
}
