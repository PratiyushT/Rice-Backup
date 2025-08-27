use rand::Rng;
use std::{cmp::Ordering, io};

fn main() {
    /* Generating a random number between 0 and 100 */
    let rand_num = rand::thread_rng().gen_range(0..100);

    /* Tracking user error */
    let mut count = 0;

    /* Looping to continue the game. */
    loop {
        if count < 5 {

            count += 1;

            /* Getting user's input */
            println!("Guess the number: ");
            let mut input = String::new();
            io::stdin()
                .read_line(&mut input)
                .expect("Please enter a proper value");

            /* Prasing the input */
            let input: u64 = input
                .trim()
                .parse()
                .expect("Error parsing the input. Please enter a valid number");

            match input.cmp(&rand_num) {
                Ordering::Less => {
                    println!("The number you have guessed is too low. Guess higher!");
                    continue;
                }
                Ordering::Greater => {
                    println!("Too High!");
                    continue;
                },
                Ordering::Equal => {
                    println!("Perfect! You Win! You needed {count} tries to win!");
                    break;
                },
            }
        }else{
            println!("You have guesses wrong 5 times. Game Over You Loser!!!!")
        }
    }
}
