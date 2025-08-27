// TODO: based on what you learned in this section, replace `todo!()` with
//  the correct **stack size** for the respective type.
#[cfg(test)]
mod tests {
    use std::mem::size_of;

    #[test]
    fn u16_size() {
        assert_eq!(size_of::<u16>(), size_of::<u16>());
    }

    #[test]
    fn i32_size() {
        assert_eq!(size_of::<i32>(), size_of::<i32>());
    }

    #[test]
    fn bool_size() {
        assert_eq!(size_of::<bool>(), size_of::<bool>());
    }
}
