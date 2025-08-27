struct Counter{
    current: u32,
    max: u32,
}


impl Iterator for Counter{
    type Item=u32;

    fn next(&mut self) -> Option<Self::Item>{
        if self.current <= self.max{
            let val = self.current;
            self.current +=1;
            Some(val)
        }else{
            None
        }
    }
}

impl IntoIterator for &Counter{
    type Item = u32;
    type IntoIter = Self;

    fn into_iter(&self)-> Self{
         &Counter { current: self.current, max: self.max }
    }
}

fn main(){
    let mut counter = Counter{current: 0, max:5};
        // Manually call next() to see how it works
    println!("Manual iteration using next(): {:?}", counter.next());
    println!("Manual iteration using next(): {:?}", counter.next());
    println!("Manual iteration using next(): {:?}", counter.next());
    println!("Manual iteration using next(): {:?}", counter.next());
    println!("Manual iteration using next(): {:?}", counter.next());
    println!("Manual iteration using next(): {:?}", counter.next());
    println!("Manual iteration using next(): {:?}", counter.next());

}