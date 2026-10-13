#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
mkdir tmp/class/class -p
cd tmp/class/class || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require class/class

declare -a tests

tests=("class.test.define_and_new" "class.test.properties")
tests+=("class.test.methods" "class.test.methods_as_code")
tests+=("class.test.method_defined_later" "class.test.static_methods")
tests+=("class.test.instances_are_separate" "class.test.inheritance")
tests+=("class.test.super" "class.test.delete")
tests+=("class.test.declared_properties")
tests+=("class.test.listing")
tests+=("class.test.nothing_is_executed")
tests+=("class.test.refusals" "class.test.constructor_that_fails")
tests+=("class.test.subshells")

function person_new {
    class.set "$1" name "$2"
    class.set "$1" age "${3:-0}"
}

function person_greet {
    echo "${2:-Hello}, I am $("$1.name")"
}

function class.test.define_and_new {
    intro "class.define and class.new"
    class.define Person person_new
    class.new Person alice "Alice" 30
    assert_equals "Alice" "$(class.get alice name)" "property set by the constructor"
    assert_equals "30" "$(class.get alice age)" "second property"
    assert_equals "Person" "$(class.class_of alice)" "class of the instance"
    class.define Empty
    class.new Empty nobody
    assert_equals "" "$(class.properties nobody)" "a class without a constructor"
    success
}

function class.test.properties {
    intro "properties, with the functions instance.property"
    assert_equals "Alice" "$(alice.name)" "get through the function"
    alice.name "Alice Cooper"
    assert_equals "Alice Cooper" "$(alice.name)" "set through the function"
    class.set alice city "New York"
    assert_equals "New York" "$(alice.city)" "a property that is new gets its function"
    assert_true "has" class.has alice city
    assert_false "has not" quietly class.has alice country
    assert_false "missing property" quietly class.get alice country
    assert_equals "age
city
name" "$(class.properties alice | sort)" "property names"
    assert_equals "age=30
city=New York
name=Alice Cooper" "$(class.dump alice)" "dump, sorted"
    local nasty
    nasty=$'multi\nline "quotes" \'single\' $(touch pwned) `touch pwned` \\ back ✓'
    alice.name "$nasty"
    assert_equals "$nasty" "$(alice.name)" "a value with everything in it"
    alice.name ""
    assert_true "an empty value is a value" class.has alice name
    assert_equals "" "$(alice.name)" "empty value"
    alice.name "Alice"
    test ! -e pwned || fail "A value was executed"
    success
}

function class.test.methods {
    intro "class.define_method with a function"
    class.define_method Person greet person_greet
    assert_equals "Hello, I am Alice" "$(alice.greet)" "through the function"
    assert_equals "Hi, I am Alice" "$(alice.greet Hi)" "with an argument"
    assert_equals "Hi, I am Alice" "$(class.invoke alice greet Hi)" "through class.invoke"
    success
}

function class.test.methods_as_code {
    intro "class.define_method with code"
    class.define_method Person shout 'echo "${2^^}, SAYS $("$1.name")"'
    assert_equals "HEY, SAYS Alice" "$(alice.shout hey)" "code gets the instance as the first argument"
    success
}

function class.test.method_defined_later {
    intro "a method defined after the instance was made"
    class.define_method Person farewell 'echo "Bye from $("$1.name")"'
    assert_equals "Bye from Alice" "$(alice.farewell)" "instances that exist get it too"
    class.new Person carol "Carol" 41
    assert_equals "Bye from Carol" "$(carol.farewell)" "and so do new ones"
    class.delete carol
    success
}

function class.test.static_methods {
    intro "class.define_static_method"
    class.define_static_method Person species 'echo "human"'
    class.define_static_method Person describe 'echo "A person called $1 of age $2"'
    assert_equals "human" "$(Person.species)" "through Class.method"
    assert_equals "A person called Ann of age 9" "$(Person.describe Ann 9)" "with arguments"
    assert_equals "human" "$(class.invoke_static Person species)" "through class.invoke_static"
    class.invoke_static Person nothing >/dev/null 2>&1
    assert_equals "127" "$?" "static method that does not exist"
    success
}

function class.test.instances_are_separate {
    intro "instances do not share properties"
    class.new Person bob "Bob" 25
    bob.name "Robert"
    assert_equals "Robert" "$(bob.name)" "changed"
    assert_equals "Alice" "$(alice.name)" "the other is not"
    assert_equals "Robert, I am Robert" "$(bob.greet Robert)" "methods use their own instance"
    success
}

function student_new {
    class.construct Person "$1" "$2" "$3"
    class.set "$1" school "$4"
}

function student_greet {
    class.invoke_as Person "$1" greet "$2"
    echo "I study at $("$1.school")"
}

function class.test.inheritance {
    intro "class.extends"
    class.define Student student_new
    class.extends Student Person
    class.new Student dave "Dave" 20 "MIT"
    assert_equals "Dave" "$(dave.name)" "property set by the constructor of the parent"
    assert_equals "MIT" "$(dave.school)" "property of the child"
    assert_equals "Hello, I am Dave" "$(dave.greet)" "method of the parent"
    assert_equals "human" "$(class.invoke_static Student species)" "static method of the parent"
    assert_true "instance of its own class" class.instance_of dave Student
    assert_true "instance of the parent" class.instance_of dave Person
    assert_false "not an instance of an unrelated class" class.instance_of dave Empty
    assert_false "the parent is not a student" class.instance_of alice Student
    class.define Graduate
    class.extends Graduate Student
    class.new Graduate erin "Erin" 30 "Oxford"
    assert_equals "Erin" "$(erin.name)" "constructor two levels up"
    assert_true "instance of the grandparent" class.instance_of erin Person
    assert_equals "farewell
greet
shout" "$(class.methods Graduate)" "methods include those of all ancestors"
    success
}

function class.test.super {
    intro "a method that calls the one it replaces"
    class.define_method Student greet student_greet
    assert_equals "Hi, I am Dave
I study at MIT" "$(dave.greet Hi)" "override with a call to the parent"
    assert_equals "Hello, I am Alice" "$(alice.greet)" "the parent is unchanged"
    success
}

function class.test.delete {
    intro "class.delete"
    class.new Person temp "Temp" 1
    assert_true "the function exists" quietly declare -F temp.name
    class.delete temp
    assert_false "the function is gone" quietly declare -F temp.name
    assert_false "the method function is gone" quietly declare -F temp.greet
    assert_false "the instance is gone" quietly class.get temp name
    assert_equals "" "$(class.instances | grep '^temp$')" "not in the list"
    class.new Person temp "Again" 2
    assert_equals "Again" "$(temp.name)" "the name can be used again"
    assert_equals "2" "$(temp.age)" "with nothing left of the old one"
    class.delete temp
    success
}

function class.test.declared_properties {
    intro "class.define_property"
    class.define Vehicle
    class.define_property Vehicle wheels 4
    class.define_property Vehicle colour
    class.new Vehicle car
    assert_equals "4" "$(car.wheels)" "the default"
    assert_false "no default, no value" quietly class.has car colour
    car.colour red
    assert_equals "red" "$(car.colour)" "the first write goes through the function"
    car.wheels 3
    assert_equals "3" "$(car.wheels)" "a default can be changed"
    class.new Vehicle other
    assert_equals "4" "$(other.wheels)" "and is not shared"
    # An instance that exists gets a property that is declared later
    class.define_property Vehicle plate "unknown"
    assert_equals "unknown" "$(car.plate)" "late declaration, existing instance"
    car.plate "AB-123"
    class.define_property Vehicle plate "changed default"
    assert_equals "AB-123" "$(car.plate)" "what the instance has is not replaced by a default"
    # Declared properties are inherited
    class.define Truck
    class.extends Truck Vehicle
    class.define_property Truck load 0
    class.new Truck big
    assert_equals "4 0" "$(big.wheels) $(big.load)" "own and inherited defaults"
    assert_equals "" "$(class.methods Truck)" "a declaration is not a method"
    # The default is a value, not code
    class.define_property Vehicle note '$(touch pwned); `touch pwned`'
    class.new Vehicle tricky
    assert_equals '$(touch pwned); `touch pwned`' "$(tricky.note)" "a default with code in it"
    test ! -e pwned || fail "A default was executed"
    # Properties and methods cannot share a name
    assert_false "a method that is a property" quietly class.define_method Vehicle wheels 'echo no'
    class.define_method Vehicle honk 'echo beep'
    assert_false "a property that is a method" quietly class.define_property Vehicle honk
    assert_equals "beep" "$(car.honk)" "the method works"
    class.delete car
    class.delete other
    class.delete big
    class.delete tricky
    success
}

function class.test.listing {
    intro "class.instances and class.methods"
    assert_equals "alice
bob
dave
erin
nobody" "$(class.instances)" "all instances"
    assert_equals "alice
bob
dave
erin" "$(class.instances Person)" "instances of Person and what extends it"
    assert_equals "dave
erin" "$(class.instances Student)" "instances of Student and Graduate"
    assert_equals "farewell
greet
shout" "$(class.methods Person)" "methods"
    success
}

function class.test.nothing_is_executed {
    intro "names are not code"
    quietly class.define 'Evil; touch pwned'
    quietly class.define 'Evil$(touch pwned)'
    quietly class.new Person 'x; touch pwned' a b
    quietly class.new Person 'x$(touch pwned)' a b
    quietly class.set alice 'x; touch pwned' value
    quietly class.set alice 'x$(touch pwned)' value
    quietly class.define_method Person 'm; touch pwned' 'echo hi'
    quietly class.define_static_method Person 'm$(touch pwned)' 'echo hi'
    quietly class.invoke alice 'greet; touch pwned'
    quietly class.extends 'Person; touch pwned' Student
    test ! -e pwned || fail "A name was executed"
    local function_name
    while read -r _ _ function_name; do
        [[ "$function_name" != *touch* ]] || fail "A function was made of a name: $function_name"
    done < <(declare -F)
    success
}

function class.test.refusals {
    intro "what is refused"
    assert_false "class that exists" quietly class.define Person
    assert_false "instance that exists" quietly class.new Person alice "Alice" 1
    assert_false "unknown class" quietly class.new Nothing x
    assert_false "unknown instance" quietly class.get nobody_here name
    assert_false "constructor that is no function" quietly class.define Broken not_a_function
    assert_false "extend an unknown class" quietly class.extends Person Unknown
    assert_false "extend as an unknown class" quietly class.extends Unknown Person
    assert_false "a class as its own parent" quietly class.extends Person Person
    assert_false "a cycle" quietly class.extends Person Student
    assert_false "a property named like a method" quietly class.set alice greet "no"
    assert_equals "Hello, I am Alice" "$(alice.greet)" "the method is still there"
    assert_false "an invalid name" quietly class.new Person "with space" x
    assert_false "an empty name" quietly class.new Person "" x
    quietly class.invoke alice nothing
    assert_equals "127" "$?" "a method that does not exist"
    # Functions that are not ours are not overwritten
    function mine.name {
        echo "mine"
    }
    class.new Empty mine
    quietly class.set mine name "theirs"
    test $? -ne 0 || fail "A function of the user was overwritten"
    assert_equals "mine" "$(mine.name)" "the function is still the user's"
    class.delete mine
    assert_equals "mine" "$(mine.name)" "and deleting the instance leaves it alone"
    unset -f mine.name
    success
}

function failing_constructor {
    class.set "$1" half "done"
    return 1
}

function class.test.constructor_that_fails {
    intro "a constructor that fails leaves nothing behind"
    class.define Fragile failing_constructor
    class.define_method Fragile ping 'echo pong'
    quietly class.new Fragile broken
    test $? -ne 0 || fail "class.new should fail"
    assert_false "no instance" quietly class.class_of broken
    assert_false "no property function" quietly declare -F broken.half
    assert_false "no method function" quietly declare -F broken.ping
    success
}

function class.test.subshells {
    intro "what a subshell can and cannot do"
    local result
    result="$(alice.name "Changed in a subshell"; alice.name)"
    assert_equals "Changed in a subshell" "$result" "inside the subshell it works"
    assert_equals "Alice" "$(alice.name)" "and is gone when the subshell ends"
    success
}

echo "Testing class/class"

for test in "${tests[@]}"; do
    "$test"
done

teardown
