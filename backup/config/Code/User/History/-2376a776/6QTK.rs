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
            Some(Val)
        }else{
            None
        }
    }
}

fn main(){

}