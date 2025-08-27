use std::{io, cmp::Ordering};
use rand::Rng;

fn main(){
    /* Generating a random number between 0 and 100 */
    let rand_num = rand::thread_rng().gen_range(0..100);

    /* Looping to continue the game. */
    loop{
    /* Getting user's input */
    let mut input = String::new();
    io::stdin()
    .read_line(&mut input)
    .expect("Please enter a proper value");

    /* Prasing the input */
    let input:u64 = input.trim().parse().expect("Error parsing the input. Please enter a valid number");


    match input.cmp(&rand_num){
        Ordering::Less => println!("Too Low!"),
        Ordering::Greater => println!("Too High!"),
        Ordering::Equal => println!("Perfect!")
    }

    println!("You have guessed {} and the number is {}", input, rand_num);
}

}