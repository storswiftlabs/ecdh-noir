use dep::std::println;

mod fp;
mod fq;
mod swcurve;

use fp::PrimeField as Fp;
use fq::PrimeField as Fq;
use swcurve::Point;
use swcurve::Curve;

struct Secp256r1 {
    curve: Curve,
}

fn secp256r1() -> Secp256r1 {
    Secp256r1 {
        curve: Curve::new(
            // a  FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC
            Fp::from_limbs([0xfffffffffffffc, 0x0000ffffffffff, 0x00000000000000, 0x00000001000000, 0xffffffff]),
            // b 5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B
            Fp::from_limbs([0xce3c3e27d2604b, 0x06b0cc53b0f63b, 0x55769886bc651d, 0xaa3a93e7b3ebbd, 0x5ac635d8]),
            Point::from_affine( 
                // G_x 6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296
                Fp::from_limbs(
                    [0xA13945D898C296,0x7D812DEB33A0F4,0xE563A440F27703,0xE12C4247F8BCE6,0x6B17D1F2]
                ),
                // G_y 4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5
                Fp::from_limbs(
                    [ 0xB6406837BF51F5,0x33576B315ECECB,0x4A7C0F9E162BCE,0xFE1A7F9B8EE7EB,0x4FE342E2 ]
                ),
            ),
        ),
    }
}

fn verify_signature(pubkey: Point, sig_r: Fq, sig_s: Fq, msghash: Fq) -> bool {
    let Secp256r1 { curve } = secp256r1();
    
    assert(!pubkey.is_zero());
    assert(curve.contains(pubkey));

    assert(!sig_r.is_zero());
    assert(!sig_s.is_zero());
    
    let s_inv = sig_s.invert();
    let you1 = msghash.mul(s_inv);
    let you2 = sig_r.mul(s_inv);
    
    let u1G = curve.mul(you1, curve.gen);
    let u2A = curve.mul(you2, pubkey);
    
    let sum = curve.add(u1G, u2A);

    let x = sum.to_affine().0;
    let xq = Fq::from_biguint56(x.to_biguint56());

    sig_r.eq(xq)
}

#[test]
fn test_secp256r1_zero() {
    assert(Point::zero().is_zero());
}

#[test]
fn test_secp256r1_add1() {
    let Secp256r1 { curve } = secp256r1();

    let p = curve.add(Point::zero(), Point::zero());
    assert(p.is_zero());
}

#[test]
fn test_secp256r1_add2() {
    let Secp256r1 { curve } = secp256r1();

    let p = curve.add(curve.gen, Point::zero());
    assert(p.eq(curve.gen));
}

#[test]
fn test_secp256r1_add3() {
    let Secp256r1 { curve } = secp256r1();

    let p1 = curve.add(curve.gen, curve.gen);
    let p2 = Point::from_affine( 
        Fp::from_bytes([
            0xe5, 0x9e, 0x70, 0x5c, 0xb9, 0x09, 0xac, 0xab, 
            0xa7, 0x3c, 0xef, 0x8c, 0x4b, 0x8e, 0x77, 0x5c, 
            0xd8, 0x7c, 0xc0, 0x95, 0x6e, 0x40, 0x45, 0x30, 
            0x6d, 0x7d, 0xed, 0x41, 0x94, 0x7f, 0x04, 0xc6
        ]),
        Fp::from_bytes([
            0x2a, 0xe5, 0xcf, 0x50, 0xa9, 0x31, 0x64, 0x23, 
            0xe1, 0xd0, 0x66, 0x32, 0x65, 0x32, 0xf6, 0xf7,
            0xee, 0xea, 0x6c, 0x46, 0x19, 0x84, 0xc5, 0xa3, 
            0x39, 0xc3, 0x3d, 0xa6, 0xfe, 0x68, 0xe1, 0x1a
        ]),
    );

    assert(p1.eq(p2));
}

#[test]
fn test_secp256r1_add4() {
    let Secp256r1 { curve } = secp256r1();

    let p1 = curve.add(curve.double(curve.gen), curve.gen);
    let p2 = Point::from_affine( 
        Fp::from_bytes([
            0xf9, 0x36, 0xe0, 0xbc, 0x13, 0xf1, 0x01, 0x86, 
            0xb0, 0x99, 0x6f, 0x83, 0x45, 0xc8, 0x31, 0xb5, 
            0x29, 0x52, 0x9d, 0xf8, 0x85, 0x4f, 0x34, 0x49, 
            0x10, 0xc3, 0x58, 0x92, 0x01, 0x8a, 0x30, 0xf9
        ]),
        Fp::from_bytes([
            0x72, 0xe6, 0xb8, 0x84, 0x75, 0xfd, 0xb9, 0x6c, 
            0x1b, 0x23, 0xc2, 0x34, 0x99, 0xa9, 0x00, 0x65, 
            0x56, 0xf3, 0x37, 0x2a, 0xe6, 0x37, 0xe3, 0x0f, 
            0x14, 0xe8, 0x2d, 0x63, 0x0f, 0x7b, 0x8f, 0x38
        ]),
    );
    assert(p1.eq(p2));
}

#[test]
fn test_secp256r1_double1() {
    let Secp256r1 { curve } = secp256r1();

    let p = curve.double(Point::zero());
    assert(p.is_zero());
}

#[test]
fn test_secp256r1_double2() {
    let Secp256r1 { curve } = secp256r1();

    let p1 = curve.double(curve.gen);
    let p2 = Point::from_affine( 
        Fp::from_bytes([
            0xe5, 0x9e, 0x70, 0x5c, 0xb9, 0x09, 0xac, 0xab, 
            0xa7, 0x3c, 0xef, 0x8c, 0x4b, 0x8e, 0x77, 0x5c, 
            0xd8, 0x7c, 0xc0, 0x95, 0x6e, 0x40, 0x45, 0x30, 
            0x6d, 0x7d, 0xed, 0x41, 0x94, 0x7f, 0x04, 0xc6
        ]),
        Fp::from_bytes([
            0x2a, 0xe5, 0xcf, 0x50, 0xa9, 0x31, 0x64, 0x23, 
            0xe1, 0xd0, 0x66, 0x32, 0x65, 0x32, 0xf6, 0xf7,
            0xee, 0xea, 0x6c, 0x46, 0x19, 0x84, 0xc5, 0xa3, 
            0x39, 0xc3, 0x3d, 0xa6, 0xfe, 0x68, 0xe1, 0x1a
        ]),
    );

    assert(p1.eq(p2));
}

#[test]
fn test_secp256r1_mul1() {
    let Secp256r1 { curve } = secp256r1();

    let p = curve.mul(Fq::from_u56(2), Point::zero());
    assert(p.is_zero());
}

#[test]
fn test_secp256r1_mul2() {
    let Secp256r1 { curve } = secp256r1();

    let p = curve.mul(Fq::zero(), curve.gen);
    assert(p.is_zero());
}

#[test]
fn test_secp256r1_mul3() {
    let Secp256r1 { curve } = secp256r1();

    let p = curve.mul(Fq::one(), curve.gen);
    assert(p.eq(curve.gen));
}

#[test]
fn test_secp256r1_mul4() {
    let Secp256r1 { curve } = secp256r1();

    let p1 = curve.mul(Fq::from_u56(2), curve.gen);
    let p2 = Point::from_affine( 
        Fp::from_bytes([
            0xe5, 0x9e, 0x70, 0x5c, 0xb9, 0x09, 0xac, 0xab, 
            0xa7, 0x3c, 0xef, 0x8c, 0x4b, 0x8e, 0x77, 0x5c, 
            0xd8, 0x7c, 0xc0, 0x95, 0x6e, 0x40, 0x45, 0x30, 
            0x6d, 0x7d, 0xed, 0x41, 0x94, 0x7f, 0x04, 0xc6
        ]),
        Fp::from_bytes([
            0x2a, 0xe5, 0xcf, 0x50, 0xa9, 0x31, 0x64, 0x23, 
            0xe1, 0xd0, 0x66, 0x32, 0x65, 0x32, 0xf6, 0xf7,
            0xee, 0xea, 0x6c, 0x46, 0x19, 0x84, 0xc5, 0xa3, 
            0x39, 0xc3, 0x3d, 0xa6, 0xfe, 0x68, 0xe1, 0x1a
        ]),
    );

    assert(p1.eq(p2));
}

#[test]
fn test_secp256r1_mul5() {
    let Secp256r1 { curve } = secp256r1();

    let p1 = curve.mul(Fq::from_u56(3), curve.gen);
    let p2 = Point::from_affine( 
        Fp::from_bytes([
            0xf9, 0x36, 0xe0, 0xbc, 0x13, 0xf1, 0x01, 0x86, 
            0xb0, 0x99, 0x6f, 0x83, 0x45, 0xc8, 0x31, 0xb5, 
            0x29, 0x52, 0x9d, 0xf8, 0x85, 0x4f, 0x34, 0x49, 
            0x10, 0xc3, 0x58, 0x92, 0x01, 0x8a, 0x30, 0xf9
        ]),
        Fp::from_bytes([
            0x72, 0xe6, 0xb8, 0x84, 0x75, 0xfd, 0xb9, 0x6c, 
            0x1b, 0x23, 0xc2, 0x34, 0x99, 0xa9, 0x00, 0x65, 
            0x56, 0xf3, 0x37, 0x2a, 0xe6, 0x37, 0xe3, 0x0f, 
            0x14, 0xe8, 0x2d, 0x63, 0x0f, 0x7b, 0x8f, 0x38
        ]),
    );

    assert(p1.eq(p2));
}

#[test]
fn test_secp256r1_verification_preshashed() {
    let pubkey = Point::from_affine(
        Fp::from_bytes([
            0xc7, 0x47, 0xe2, 0x47, 0x2a, 0x8e, 0xa6, 0x52,
            0xb7, 0xc2, 0x43, 0x19, 0x9b, 0xd4, 0x42, 0x34,
            0x5d, 0xae, 0xe6, 0x1a, 0x7b, 0x7c, 0x47, 0x35,
            0x62, 0xc8, 0xf3, 0x47, 0x9e, 0x4d, 0x43, 0xa0,
        ]),
        Fp::from_bytes([
            0xd7, 0x68, 0x73, 0x03, 0x3b, 0xe5, 0xbe, 0x3c,
            0x59, 0xa1, 0x77, 0xd8, 0x2e, 0x4c, 0x79, 0x6f,
            0x69, 0x4c, 0xa2, 0x93, 0xe6, 0xc7, 0xb6, 0xa3,
            0x27, 0xbc, 0x19, 0x54, 0x42, 0xba, 0x3a, 0x89,
        ])
    );
    let r = Fq::from_bytes([
        0xfd, 0x54, 0xf4, 0x8d, 0x4e, 0x5a, 0xe5, 0x9a,
        0xdb, 0x61, 0x80, 0xc3, 0x98, 0x97, 0x8d, 0xad,
        0x2b, 0xaa, 0x31, 0x0e, 0x4a, 0x6f, 0x34, 0x70,
        0xc3, 0x7d, 0x42, 0xab, 0x80, 0x1c, 0x08, 0xe5,
    ]);
    let s = Fq::from_bytes([
        0x55, 0xcd, 0x5f, 0x71, 0x9a, 0xe4, 0x61, 0x01,
        0x69, 0x69, 0xeb, 0xd6, 0x89, 0x0b, 0xbb, 0xec,
        0x80, 0xf4, 0x61, 0x1d, 0x93, 0xcc, 0x70, 0x87,
        0xb7, 0x71, 0x4e, 0x34, 0x94, 0x98, 0x11, 0x28,
    ]);
    let msghash = Fq::from_bytes([
        0xe2, 0xc1, 0xc8, 0x3a, 0x63, 0xb4, 0x06, 0x68,
        0xda, 0xc2, 0xd9, 0x35, 0xd0, 0x49, 0x69, 0x47,
        0x35, 0x88, 0x35, 0x8d, 0x7e, 0xcd, 0x21, 0x1f,
        0x12, 0xd2, 0x5c, 0x3a, 0x12, 0xf4, 0x73, 0x3a,
    ]);

    assert(verify_signature(pubkey, r, s, msghash));
}