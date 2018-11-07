#[macro_use] extern crate rustler;
// #[macro_use] extern crate rustler_codegen;
#[macro_use] extern crate lazy_static;

extern crate rayon;
extern crate scoped_pool;

use rustler::{Env, Term, NifResult, Encoder, Error};
use rustler::env::{OwnedEnv, SavedTerm};
use rustler::types::map::MapIterator;
use rustler::types::binary::Binary;

use rustler::types::tuple::make_tuple;
use std::mem;
use std::slice;
use std::str;
use std::ops::RangeInclusive;

use rayon::prelude::*;

mod atoms {
    rustler_atoms! {
        atom ok;
        //atom error;
        //atom __true__ = "true";
        //atom __false__ = "false";
    }
}

rustler_export_nifs! {
    "Elixir.LogisticMapNif",
    [("calc", 3, calc),
     ("map_calc_list", 4, map_calc_list),
     ("to_binary", 1, to_binary),
     ("map_calc_binary", 4, map_calc_binary),
     ("call_empty", 3, call_empty),
     ("map_calc_t1", 4, map_calc_t1),
     ("init_nif", 0, init_nif)],
    None
}

lazy_static! {
    static ref POOL:scoped_pool::Pool = scoped_pool::Pool::new(2);
}


fn init_nif<'a>(env: Env<'a>, _args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let _ = rayon::ThreadPoolBuilder::new().num_threads(32).build_global().unwrap();
    Ok(atoms::ok().encode(env))
}


fn to_range(arg: Term) -> Result<RangeInclusive<i64>, Error> {
    let vec:Vec<(Term, Term)> = arg.decode::<MapIterator>()?.collect();
    match (&*vec[0].0.atom_to_string()?, &*vec[0].1.atom_to_string()?) {
        ("__struct__", "Elixir.Range") => {
            let first = vec[1].1.decode::<i64>()?;
            let last = vec[2].1.decode::<i64>()?;
            Ok(first ..= last)
        },
        _ => Err(Error::BadArg),
    }
}

fn to_list(arg: Term) -> Result<Vec<i64>, Error> {
    match (arg.is_map(), arg.is_list() || arg.is_empty_list()) {
        (true, false) => Ok(to_range(arg)?.collect::<Vec<i64>>()),
        (false, true) => Ok(arg.decode::<Vec<i64>>()?),
        _ => Err(Error::BadArg),
    }
}

fn calc<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let x: i64 = try!(args[0].decode());
    let p: i64 = try!(args[1].decode());
    let mu: i64 = try!(args[2].decode());

    Ok((atoms::ok(), mu * x * (x + 1) % p).encode(env))
}

fn loop_calc(num: i64, init: i64, p: i64, mu: i64) -> i64 {
    let mut x: i64 = init;
    for _i in 0..num {
        x = mu * x * (x + 1) % p;
    }
    x
}

fn map_calc_list<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let num: i64 = try!(args[1].decode());
    let p: i64 = try!(args[2].decode());
    let mu: i64 = try!(args[3].decode());
    match to_list(args[0]) {
        Ok(list) => Ok(list.iter().map(|&x| loop_calc(num, x, p, mu)).collect::<Vec<i64>>().encode(env)),
        Err(err) => Err(err),
    }
}

fn to_binary<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    match to_list(args[0]) {
        Ok(result) => Ok(result.iter().map(|i| unsafe {
            let ip: *const i64 = i;
            let bp: *const u8 = ip as *const _;
            let _bs: &[u8] = {
                slice::from_raw_parts(bp, mem::size_of::<i64>())
            };
            *bp
        }).collect::<Vec<u8>>()
        .iter().map(|&s| s as char).collect::<String>()
        .encode(env)),
        Err(err) => Err(err),
    }
}

fn map_calc_binary<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let in_binary : Binary = args[0].decode()?;
    let num: i64 = try!(args[1].decode());
    let p: i64 = try!(args[2].decode());
    let mu: i64 = try!(args[3].decode());

    let res = in_binary.iter().map(|&s| s as i64).map(|x| loop_calc(num, x, p, mu)).collect::<Vec<i64>>();
    Ok(res.encode(env))
}

fn call_empty<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let _p: i64 = try!(args[1].decode());
    let _mu: i64 = try!(args[2].decode());

    match to_list(args[0]) {
        Ok(result) => Ok(result.iter().map(|&x| x).collect::<Vec<i64>>().encode(env)),
        Err(err) => Err(err),
    }
}

fn map_calc_t1<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let pid = env.pid();
    let mut my_env = OwnedEnv::new();

    let saved_list = my_env.run(|env| -> NifResult<SavedTerm> {
        let list_arg = args[0].in_env(env);
        let num      = args[1].in_env(env);
        let p        = args[2].in_env(env);
        let mu       = args[3].in_env(env);
        Ok(my_env.save(make_tuple(env, &[list_arg, num, p, mu])))
    })?;

    POOL.spawn(move || {
        my_env.send_and_clear(&pid, |env| {
            let result: NifResult<Term> = (|| {
                let tuple = saved_list.load(env).decode::<(Term, i64, i64, i64)>()?;
                let num = tuple.1;
                let p = tuple.2;
                let mu = tuple.3;

                match to_list(tuple.0) {
                    Ok(result) => Ok(result.par_iter().map(|&x| loop_calc(num, x, p, mu)).collect::<Vec<i64>>().encode(env)),
                    Err(err) => Err(err)
                }
            })();
            match result {
                Err(_err) => env.error_tuple("test failed".encode(env)),
                Ok(term) => term
            }
        });
    });
    Ok(atoms::ok().to_term(env))
}
