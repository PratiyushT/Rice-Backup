// TODO: Define a new `SaturatingU16` type.
//   It should hold a `u16` value.
//   It should provide conversions from `u16`, `u8`, `&u16` and `&u8`.
//   It should support addition with a right-hand side of type
//   SaturatingU16, u16, &u16, and &SaturatingU16. Addition should saturate at the
//   maximum value for `u16`.
//   It should be possible to compare it with another `SaturatingU16` or a `u16`.
//   It should be possible to print its debug representation.
//
// Tests are located in the `tests` folder—pay attention to the visibility of your types and methods.

use std::ops::{Add, Deref};

/* Defining the Struct */
#[derive(Debug, PartialEq)]
pub struct SaturatingU16(u16);

/* Implement From*/
impl From<u8> for SaturatingU16{
    fn from(value: u8) -> Self {
        SaturatingU16(value as u16)
    }
}

impl From<u16> for SaturatingU16{
    fn from(value: u16) -> Self {
        SaturatingU16(value)
    }
}
impl From<&u8> for SaturatingU16{
    fn from(value: &u8) -> Self {
        SaturatingU16(*value as u16)
    }
}
impl From<&u16> for SaturatingU16{
    fn from(value: &u16) -> Self {
        SaturatingU16(*value)
    }
}

/* Deref Trait */

impl Deref for SaturatingU16{
    type Target=SaturatingU16;
    fn deref(&self) -> &Self::Target {
        self
    }
}


/* Implementing Add traits for various rhs values on our struct */
impl Add<&u16> for SaturatingU16{
    type Output = SaturatingU16;
    fn add(self, rhs: &u16) -> Self::Output {
        let sum = self.0.saturating_add(*rhs);
        SaturatingU16(sum)
    }
}
impl Add<u16> for SaturatingU16{
    type Output = SaturatingU16;
    fn add(self, rhs: u16) -> Self::Output {
        let sum = self.0.saturating_add(rhs);
        SaturatingU16(sum)
    }
}
impl Add for SaturatingU16{
    type Output = SaturatingU16;
    fn add(self, rhs: Self) -> Self::Output {
        let sum =self.0.saturating_add(rhs.0);
        SaturatingU16(sum)
    }
}
impl Add<&SaturatingU16> for SaturatingU16{
    type Output = SaturatingU16;

    fn add(self, rhs: &SaturatingU16) -> Self::Output {
        let sum = self.0.saturating_add(*rhs.0);
    }
}

