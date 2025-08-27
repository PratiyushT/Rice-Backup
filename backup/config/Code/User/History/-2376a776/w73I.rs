fn main(){
    let num = vec![1,2,3,4,5,56];
    let squared_num = num.iter()
    .map(|num: &i32| num * num)
    .collect();

    println!("{:?}", squared_num)
}