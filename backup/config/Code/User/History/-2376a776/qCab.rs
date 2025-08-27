fn main(){
    let num = vec![1,2,3,4,5,56];
    let squared_num = num.map(|num| => num * num).collect();

    println!("{:?}", squared_num)
}