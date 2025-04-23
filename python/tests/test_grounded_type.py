import unittest

from hyperon import *
import hyperonpy as hp

class GroundedTypeTest(unittest.TestCase):

    def test_apply_type(self):
        metta = MeTTa(env_builder=Environment.test_env())
        self.assertEqual(
            metta.parse_single("+").get_grounded_type(),
            metta.parse_single("*").get_grounded_type())
        self.assertEqual(
            metta.run("!(+ (* 1 4) 2)")[0][0].get_grounded_type(),
            metta.parse_single("0").get_grounded_type())
        self.assertEqual(
            metta.run("!(or True False)")[0][0].get_grounded_type(),
            metta.parse_single("False").get_grounded_type())
        self.assertEqual(
            metta.run("!(> (* 2 2) 1)")[0][0].get_grounded_type(),
            metta.run("!(or True True)")[0][0].get_grounded_type())
        metta.register_atom("untyped", ValueAtom(None))
        metta.register_atom("untop", OperationAtom("untop", lambda: None))
        self.assertEqual(
            metta.run("!(untop)")[0][0],
            metta.parse_single("()"))
        self.assertNotEqual(
            metta.run("!(> 1 1)")[0][0].get_grounded_type(),
            metta.run("!(+ 1 1)")[0][0].get_grounded_type())

    def test_higher_func(self):
        metta = MeTTa(env_builder=Environment.test_env())
        metta.register_atom(r"plus", OperationAtom("plus", lambda a, b: a + b))
        metta.register_atom(
            r"curry_num",
            OperationAtom(
                "curry_num",
                lambda op, x: [OperationAtom(
                    'lmd',
                    lambda y: op.get_object().op(x.get_object().value, y),
                    ['Number', 'Number'])],
                [['Number', 'Number', 'Number'], 'Number', ['Number', 'Number']],
                unwrap=False))
        self.assertEqual(metta.run("!((curry_num plus 1) 2)"),
                         metta.run("! 3"))

    def test_string_repr(self):
        metta = MeTTa(env_builder=Environment.test_env())
        self.assertEqual(metta.run('!(repr "A\n\tBB\x1b\u130A9")')[0][0].get_object(),
                         ValueObject("\"A\\n\\tBB\\x1b\u130A9\""))

    def test_meta_types(self):
        metta = MeTTa(env_builder=Environment.test_env())
        ### Basic functional types
        metta.register_atom(r"id_num", OperationAtom("id_num", lambda x: x, ['Number', 'Number']))
        metta.register_atom(r"as_int", OperationAtom("as_int", lambda x: x, ['Number', 'Number']))
        v1 = metta.run("!(id_num (+ 2 2))")[0]
        v2 = metta.run("! 4")[0]
        v3 = metta.run("!(as_int (+ 2 2))")[0]
        self.assertEqual(v1, v2)
        self.assertEqual(v1[0].get_grounded_type(), v2[0].get_grounded_type())
        # Python int is represented by the Rust Number grounded atom. Number is
        # implemented to have constant type "Number" which is common
        # implementation of the grounded atoms in Rust. Usually type is an
        # attribute of the atom and cannot be changed by reassigning. Thus one
        # cannot override type of the value by calling (-> Number Int)
        # function. It doesn't work for usual Rust grounded atoms.
        self.assertEqual(v1[0].get_grounded_type(), v3[0].get_grounded_type())
        # Untyped symbols don't cause type error, but the expression is not reduced
        self.assertEqual(metta.run("!(id_num untyp)"), [metta.parse_all("(id_num untyp)")])
        # Typed symbols cause type error when evaluated
        metta.run("(: myAtom myType)")
        self.assertEqual(metta.run('''
            !(id_num myAtom)
            !(id_num False)
            '''),
            [[E(S('Error'), S('myAtom'), S('BadType'))]])
        ### Grounded functions over Atom
        ### (should use unwrap=False to deal with non-grounded atoms)
        # All grounded and ungrounded, typed and untyped symbols should be processed
        metta.register_atom(r"id_atom", OperationAtom("id_atom",
            lambda x: [x], [AtomType.ATOM, AtomType.ATOM], unwrap=False))
        self.assertEqual(metta.run('''
            !(id_atom 1)
            !(id_atom myAtom)
            !(id_atom untyp)
            ''', flat=True),
            metta.parse_all('''
            1
            myAtom
            untyp
            '''))
        # FIXME: (id_atom (+ 1 1)) gets reduced because after id_atom returns
        # (+ 1 1) it is evaluated further and becomes 2. We don't have a manner
        # to prevent evaluation in MeTTa.
        # self.assertEqual(metta.run("!(id_atom (+ 1 1))"), [metta.parse_all("(+ 1 1)")])
        ### Polymorphic without unwrapping
        # Nothing is done with `$t` on the Grounded side, but we check that:
        # - the argument has really a variable type
        # - the interpreter doesn't reject to process this grounded function
        metta.register_atom(r"id_poly_w", OperationAtom("id_poly_w", lambda x: [x], ['$t', '$t'], unwrap=False))
        self.assertEqual(metta.run('''
            !(id_poly_w 1)
            !(id_poly_w myAtom)
            !(id_poly_w untyp)
            !(id_poly_w (+ 1 1))
            !(+ 1 (id_poly_w 2))
            ''', flat=True),
            metta.parse_all('''
             1
             myAtom
             untyp
             2
             3
            ''')
        )
        ### Polymorphic with unwrapping
        # TODO: automatic unwrapping of arguments of grounded polymorphic function
        #       is not supported on the Python side
        metta.register_atom(r"id_poly_u", OperationAtom("id_poly_u", lambda x: x, ['$t', '$t']))
        ### Undefined arguments
        # It is a bad idea to have an undefined result with automatic wrapping, but it's ok here
        metta.register_atom(r"id_undef", OperationAtom("id_undef", lambda x: x, [AtomType.UNDEFINED, AtomType.UNDEFINED]))
        self.assertEqual(metta.run('''
            !(id_undef 1)
            !(id_undef False)
            !(id_undef (+ 1 1))
            ''', flat=True),
            metta.parse_all("1 False 2"))
        # This will not be reduced, because unwrapping expects a grounded atom
        self.assertEqual(metta.run('''
            !(id_undef myAtom)
            !(id_undef untyp)
            ''', flat=True),
            metta.parse_all('''
             (id_undef myAtom)
             (id_undef untyp)
            ''')
        )

    # TODO: For now OperationAtom without type has Undefined type. We discussed
    # that it would be nice to have something like *args in the future. The
    # type of untyped operations is yet another example showing this can be
    # useful. So, the type of untyped operations might become something like
    # (-> *Undefined Undefined) in the future.
    @unittest.skip("Behavior to be defined")
    def test_undefined_operation_type(self):
        metta = MeTTa(env_builder=Environment.test_env())
        metta.register_atom("untyped", ValueAtom(None))
        metta.register_atom("untop", OperationAtom("untop", lambda: None))
        self.assertNotEqual(metta.parse_single("untop").get_grounded_type(),
                metta.parse_single("untyped").get_grounded_type())

    def test_conversion_between_rust_and_python(self):
        metta = MeTTa(env_builder=Environment.test_env())
        integer = metta.run('!(+ 1 (random-int &rng 4 5))', flat=True)[0].get_object()
        self.assertEqual(integer, ValueObject(5))
        float = metta.run('!(+ 1.0 (random-float &rng 4 5))', flat=True)[0].get_object()
        self.assertTrue(float.value >= 5.0 and float.value < 6)
        bool = metta.run('!(not (flip))', flat=True)[0].get_object()
        self.assertTrue(bool.value or  not bool.value)
        false = metta.run('!(not True)', flat=True)[0].get_object()
        self.assertEqual(false, ValueObject(False))

    def test_python_value_conversion(self):
        metta = MeTTa(env_builder=Environment.test_env())
        metta.register_atom("return-int", OperationAtom("return-int", lambda: 42))
        integer = metta.run('!(return-int)', flat=True)[0].get_object()
        self.assertEqual(integer, ValueObject(42))
        metta.register_atom("return-float", OperationAtom("return-float", lambda: 4.2))
        float = metta.run('!(return-float)', flat=True)[0].get_object()
        self.assertEqual(float, ValueObject(4.2))
        metta.register_atom("return-bool", OperationAtom("return-bool", lambda: True))
        float = metta.run('!(return-bool)', flat=True)[0].get_object()
        self.assertEqual(float, ValueObject(True))

    def test_assert_grounded_value_type(self):
        with self.assertRaises(AssertionError) as cm:
            ValueAtom(42, "Int")
        msg = str(cm.exception)
        self.assertTrue(msg.startswith("Grounded int 42 can't have a custom type Int"), f"Unexpected message \"{msg}\"")
        with self.assertRaises(AssertionError) as cm:
            ValueAtom(4.2, "Float")
        msg = str(cm.exception)
        self.assertTrue(msg.startswith("Grounded float 4.2 can't have a custom type Float"), f"Unexpected message \"{msg}\"")
        with self.assertRaises(AssertionError) as cm:
            ValueAtom(True, "bool")
        msg = str(cm.exception)
        self.assertTrue(msg.startswith("Grounded bool True can't have a custom type bool"), f"Unexpected message \"{msg}\"")

if __name__ == "__main__":
    unittest.main()
