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

    ThongTinNha public thongTinNha;
    ThongTinThue private thongTinThue;
    mapping(address => uint256) public soDuTaiKhoan;

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
                10 seconds;
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
            10 seconds;

        soDuTaiKhoan[thongTinThue.nguoiThue] = msg.value;
        thongTinNha.hopDongDuocKy = true;
    }

    function rutTien(uint256 soThangMuonRut) external {
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
            thongTinThue.thoiDiemBatDau) / 10 seconds;

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
        require(
            soDuTaiKhoan[thongTinThue.nguoiThue] >= soTienRut,
            "So du khong du"
        );

        soDuTaiKhoan[thongTinThue.nguoiThue] -= soTienRut;
        soDuTaiKhoan[thongTinNha.chuNha] += soTienRut;
        thongTinThue.soThangDaThanhToan += soThangMuonRut;

        payable(thongTinNha.chuNha).transfer(soTienRut);
    }

    function giaHanHopDong(uint256 soThangThem) external payable {
        require(thongTinNha.hopDongDuocKy, "Chua co hop dong");
        require(
            msg.sender == thongTinThue.nguoiThue,
            "Chi nguoi thue moi duoc gia han"
        );
        // Giới hạn thời gian gia hạn: chỉ được phép gia hạn trong vòng 5s sau khi hết hạn
        require(
            block.timestamp <= thongTinThue.thoiDiemKetThuc + 5 seconds,
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

        // Gia hạn thời gian kết thúc hợp đồng
        thongTinThue.thoiDiemKetThuc += soThangThem * 10 seconds;

        // Cập nhật tổng số tháng trong hợp đồng
        thongTinNha.thoiGianThueThang += soThangThem;

        // Cập nhật số dư tài khoản
        soDuTaiKhoan[msg.sender] += msg.value;
    }

    function chamDutHopDong() external {
        require(thongTinNha.hopDongDuocKy, "Chua co hop dong");
        require(
            msg.sender == thongTinThue.nguoiThue ||
                msg.sender == thongTinNha.chuNha,
            "Chi chu nha hoac nguoi thue moi co quyen"
        );

        uint256 tongThangThue = thongTinNha.thoiGianThueThang;
        uint256 soThangDaSuDung = (block.timestamp -
            thongTinThue.thoiDiemBatDau) / 10 seconds;

        if (soThangDaSuDung > tongThangThue) {
            soThangDaSuDung = tongThangThue;
        }

        uint256 soTienChuaThanhToan = (soThangDaSuDung -
            thongTinThue.soThangDaThanhToan) * thongTinNha.chiPhiHangThang;

        uint256 tienHoanLai = soDuTaiKhoan[thongTinThue.nguoiThue] -
            soTienChuaThanhToan;

        // Nếu có tiền hoàn lại, thực hiện chuyển tiền
        if (tienHoanLai > 0) {
            (bool success, ) = payable(msg.sender).call{value: tienHoanLai}("");
            require(success, "Chuyen tien that bai");
        }

        // CHuyển số tiền chưa thanh toán cho chủ nhà
        if (soTienChuaThanhToan > 0) {
            soDuTaiKhoan[thongTinNha.chuNha] += soTienChuaThanhToan;
        }

        soDuTaiKhoan[thongTinThue.nguoiThue] = 0;

        // Chấm dứt hợp đồng
        thongTinNha.hopDongDuocKy = false;

        // Reset thông tin người thuê
        thongTinThue.nguoiThue = address(0);
        thongTinThue.thoiDiemBatDau = 0;
        thongTinThue.soThangDaThanhToan = 0;
        thongTinThue.thoiDiemKetThuc = 0;
    }
}
