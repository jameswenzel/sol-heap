// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseTest } from "test/BaseTest.sol";
import { MinHeapMap } from "../src/MinHeapMap.sol";
import { Node, NodeType } from "../src/lib/NodeType.sol";
import { HeapMetadata, HeapMetadataType } from "../src/lib/HeapMetadataType.sol";
import { Pointer, PointerType } from "../src/lib/PointerType.sol";

contract MinHeapMapTest is BaseTest {
    using MinHeapMap for MinHeapMap.Heap;

    MinHeapMap.Heap private heap;
    MinHeapMap.Heap private preFilled;
    uint256 nodesSlot;

    function setUp() public virtual override {
        nodesSlot = MinHeapMap._nodesSlot(heap);
        for (uint256 i = 1; i <= 257; i++) {
            preFilled.insert(i, i);
        }
    }

    function testPop() public {
        for (uint256 i = 1; i <= 257; i++) {
            assertEq(i, preFilled.peek(), "wrong peek");
            assertEq(i, preFilled.pop(), "wrong pop");
        }
    }

    function testUpdateAndGet(uint256 key, uint256 toWrap) public {
        MinHeapMap._update(nodesSlot, key, Node.wrap(toWrap));
        assertEq(Node.unwrap(MinHeapMap._get(nodesSlot, key)), toWrap);
        assertEq(Node.unwrap(heap.nodes[key]), toWrap);
    }

    function testUpdateAndGet() public {
        uint256 key = 69;
        uint256 toWrap = 420;
        MinHeapMap._update(nodesSlot, key, Node.wrap(toWrap));
        assertEq(Node.unwrap(MinHeapMap._get(nodesSlot, key)), toWrap);
        assertEq(Node.unwrap(heap.nodes[key]), toWrap);
    }

    function testPeek() public {
        uint256 value = 69;
        Node rootNode = NodeType.createNode({
            _value: value,
            _left: 0,
            _right: 0,
            _parent: 0
        });
        MinHeapMap._update(nodesSlot, 1, rootNode);
        HeapMetadata heapMetadata = HeapMetadataType.createHeapMetadata({
            _rootKey: 1,
            _size: 1,
            _lastNodeKey: 1,
            _leftmostNodeKey: 1,
            _insertPointer: PointerType.createPointer(1, false)
        });
        heap.heapMetadata = heapMetadata;
        assertEq(MinHeapMap.peek(heap), value);
    }

    function testPeek(uint32 key, uint160 value) public {
        Node rootNode = NodeType.createNode({
            _value: value,
            _left: 0,
            _right: 0,
            _parent: 0
        });
        MinHeapMap._update(nodesSlot, key, rootNode);
        HeapMetadata heapMetadata = HeapMetadataType.createHeapMetadata({
            _rootKey: key,
            _size: 1,
            _lastNodeKey: key,
            _leftmostNodeKey: key,
            _insertPointer: PointerType.createPointer(key, false)
        });
        heap.heapMetadata = heapMetadata;
        assertEq(MinHeapMap.peek(heap), value);
    }

    function testInsertAndPopOne() public {
        MinHeapMap.insert(heap, 42, 69);
        assertEq(MinHeapMap.peek(heap), 69, "peeked value incorrect");
        (
            uint256 root,
            uint256 size,
            uint256 lastNodeKey,
            uint256 leftmostNodeKey,
            Pointer insertPointer
        ) = HeapMetadataType.unpack(heap.heapMetadata);
        assertEq(root, 42, "root incorrect");
        assertEq(size, 1, "size incorrect");
        assertEq(lastNodeKey, 42, "lastNodeKey incorrect");
        assertEq(leftmostNodeKey, 42, "leftmostNodeKey incorrect");
        assertEq(Pointer.unwrap(insertPointer), 42, "insertPointer incorrect");

        uint256 value = MinHeapMap.pop(heap);
        assertEq(value, 69, "popped value incorrect");
        (root, size, lastNodeKey, leftmostNodeKey, insertPointer) =
            HeapMetadataType.unpack(heap.heapMetadata);
        assertEq(root, 0, "new root incorrect");
        assertEq(size, 0, "new size incorrect");
        assertEq(lastNodeKey, 0, "new lastNodeKey incorrect");
        assertEq(leftmostNodeKey, 0, "new leftmostNodeKey incorrect");
        assertEq(
            Pointer.unwrap(insertPointer), 0, "new insertPointer incorrect"
        );
    }

    function testInsertTwo() public {
        MinHeapMap.insert(heap, 42, 69);
        MinHeapMap.insert(heap, 43, 420);
        assertEq(MinHeapMap.peek(heap), 69, "peeked value incorrect");
        (
            uint256 root,
            uint256 size,
            uint256 lastNodeKey,
            uint256 leftmostNodeKey,
            Pointer insertPointer
        ) = HeapMetadataType.unpack(heap.heapMetadata);
        assertEq(root, 42, "root incorrect");
        assertEq(size, 2, "size incorrect");
        assertEq(lastNodeKey, 43, "lastNodeKey incorrect");
        assertEq(leftmostNodeKey, 43, "leftmostNodeKey incorrect");
        assertEq(
            Pointer.unwrap(insertPointer),
            Pointer.unwrap(PointerType.createPointer(42, true)),
            "insertPointer incorrect"
        );
    }

    function testInsertPeekAndSize69() public {
        for (uint256 i = 1; i < 16; i++) {
            heap.insert(i, i);

            assertEq(1, heap.peek(), "wrong peek");
            assertEq(i, heap.size(), "wrong size");
            assertEq(
                heap.getLeftmostKey(), // "actual"
                heap.heapMetadata.leftmostNodeKey(), // "expected"
                "wrong leftmost"
            );
        }
    }

    function testInsertReverse() public {
        for (uint256 i = 16; i < 1; i--) {
            heap.insert(i, i);
            assertEq(i, heap.peek());
            assertEq(i, heap.size());
            assertEq(heap.getLeftmostKey(), heap.heapMetadata.leftmostNodeKey());
        }
    }

    function testOneProperties() public {
        heap.insert(1, 1);
        assertEq(heap.peek(), 1, "wrong peek");
        assertEq(heap.heapMetadata.rootKey(), 1);
        assertEq(heap.heapMetadata.size(), 1);
        assertEq(heap.heapMetadata.lastNodeKey(), 1);
        assertEq(heap.heapMetadata.leftmostNodeKey(), 1);
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(1, false))
        );
    }

    function testTwoProperties() public {
        heap.insert(1, 1);
        heap.insert(2, 2);
        assertEq(heap.peek(), 1, "wrong peek");
        assertEq(heap.heapMetadata.rootKey(), 1);
        assertEq(heap.heapMetadata.size(), 2);
        assertEq(heap.heapMetadata.lastNodeKey(), 2);
        assertEq(heap.heapMetadata.leftmostNodeKey(), 2);
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(1, true))
        );

        uint256 val = heap.pop();
        assertEq(val, 1, "wrong pop");
        assertEq(heap.peek(), 2, "wrong peek");
        assertEq(heap.heapMetadata.rootKey(), 2, "wrong root");
        assertEq(heap.heapMetadata.size(), 1, "wrong size");
        assertEq(heap.heapMetadata.lastNodeKey(), 2, "wrong lastNodeKey");
        assertEq(
            heap.heapMetadata.leftmostNodeKey(), 2, "wrong leftmostNodeKey"
        );
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(2, false)),
            "wrong insertPointer"
        );
    }

    function testThreeProperties() public {
        heap.insert(1, 1);
        heap.insert(2, 2);
        heap.insert(3, 3);
        assertEq(heap.peek(), 1, "wrong peek");
        assertEq(heap.heapMetadata.rootKey(), 1);
        assertEq(heap.heapMetadata.size(), 3);
        assertEq(heap.heapMetadata.lastNodeKey(), 3);
        assertEq(heap.heapMetadata.leftmostNodeKey(), 2);
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(2, false))
        );

        uint256 val = heap.pop();
        assertEq(val, 1, "wrong pop");
        assertEq(heap.peek(), 2, "wrong peek");
        assertEq(heap.heapMetadata.rootKey(), 2, "wrong root");
        assertEq(heap.heapMetadata.size(), 2, "wrong size");
        assertEq(heap.heapMetadata.lastNodeKey(), 3, "wrong lastNodeKey");
        assertEq(
            heap.heapMetadata.leftmostNodeKey(), 3, "wrong leftmostNodeKey"
        );
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(2, true)),
            "wrong insertPointer"
        );

        val = heap.pop();
        assertEq(val, 2, "wrong pop");
        assertEq(heap.peek(), 3, "wrong peek");
        assertEq(heap.heapMetadata.rootKey(), 3, "wrong root");
        assertEq(heap.heapMetadata.size(), 1, "wrong size");
        assertEq(heap.heapMetadata.lastNodeKey(), 3, "wrong lastNodeKey");
        assertEq(
            heap.heapMetadata.leftmostNodeKey(), 3, "wrong leftmostNodeKey"
        );
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(3, false)),
            "wrong insertPointer"
        );
    }

    function testFourProperties() public {
        heap.insert(1, 1);
        heap.insert(2, 2);
        heap.insert(3, 3);
        heap.insert(4, 4);

        assertEq(heap.peek(), 1, "wrong peek");
        assertEq(heap.heapMetadata.rootKey(), 1);
        assertEq(heap.heapMetadata.size(), 4);
        assertEq(heap.heapMetadata.lastNodeKey(), 4);
        assertEq(heap.heapMetadata.leftmostNodeKey(), 4);
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(2, true))
        );

        uint256 val = heap.pop();
        assertEq(val, 1, "wrong pop");
        assertEq(heap.peek(), 2, "wrong peek");
        assertEq(heap.heapMetadata.rootKey(), 2, "wrong root");
        assertEq(heap.heapMetadata.size(), 3, "wrong size");
        assertEq(heap.heapMetadata.lastNodeKey(), 3, "wrong lastNodeKey");
        assertEq(
            heap.heapMetadata.leftmostNodeKey(), 4, "wrong leftmostNodeKey"
        );
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(4, false)),
            "wrong insertPointer"
        );

        val = heap.pop();
        require(val == 2, "wrong pop");
        require(heap.peek() == 3, "wrong peek");
        require(heap.heapMetadata.rootKey() == 3, "wrong root");
        require(heap.heapMetadata.size() == 2, "wrong size");
        require(heap.heapMetadata.lastNodeKey() == 4, "wrong lastNodeKey");
        require(
            heap.heapMetadata.leftmostNodeKey() == 4, "wrong leftmostNodeKey"
        );
        require(
            Pointer.unwrap(heap.heapMetadata.insertPointer())
                == Pointer.unwrap(PointerType.createPointer(3, true)),
            "wrong insertPointer"
        );

        val = heap.pop();
        require(val == 3, "wrong pop");
        require(heap.peek() == 4, "wrong peek");
        require(heap.heapMetadata.rootKey() == 4, "wrong root");
        require(heap.heapMetadata.size() == 1, "wrong size");
        require(heap.heapMetadata.lastNodeKey() == 4, "wrong lastNodeKey");
        require(
            heap.heapMetadata.leftmostNodeKey() == 4, "wrong leftmostNodeKey"
        );
        require(
            Pointer.unwrap(heap.heapMetadata.insertPointer())
                == Pointer.unwrap(PointerType.createPointer(4, false)),
            "wrong insertPointer"
        );
    }

    function testFiveProperties() public {
        heap.insert(1, 1);
        heap.insert(2, 2);
        heap.insert(3, 3);
        heap.insert(4, 4);
        heap.insert(5, 5);

        assertEq(heap.peek(), 1, "wrong peek");
        assertEq(heap.heapMetadata.rootKey(), 1, "wrong root");
        assertEq(heap.heapMetadata.size(), 5, "wrong size");
        assertEq(heap.heapMetadata.lastNodeKey(), 5, "wrong lastNodeKey");
        assertEq(
            heap.heapMetadata.leftmostNodeKey(), 4, "wrong leftmostNodeKey"
        );
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(3, false)),
            "wrong insertPointer"
        );

        uint256 val = heap.pop();
        assertEq(val, 1, "wrong pop");
        assertEq(heap.peek(), 2, "wrong peek");
        assertEq(heap.heapMetadata.rootKey(), 2, "wrong root");
        assertEq(heap.heapMetadata.size(), 4, "wrong size");
        assertEq(heap.heapMetadata.lastNodeKey(), 5, "wrong lastNodeKey");
        assertEq(
            heap.heapMetadata.leftmostNodeKey(), 5, "wrong leftmostNodeKey"
        );
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(4, true)),
            "wrong insertPointer"
        );

        val = heap.pop();
        // revert();
        assertEq(val, 2, "wrong pop");
        assertEq(heap.peek(), 3, "wrong peek");
        assertEq(heap.heapMetadata.rootKey(), 3, "wrong root");
        assertEq(heap.heapMetadata.size(), 3, "wrong size");
        assertEq(heap.heapMetadata.lastNodeKey(), 5, "wrong lastNodeKey");
        assertEq(
            heap.heapMetadata.leftmostNodeKey(), 4, "wrong leftmostNodeKey"
        );
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(4, false)),
            "wrong insertPointer"
        );

        val = heap.pop();
        assertEq(val, 3, "wrong pop");
        assertEq(heap.peek(), 4, "wrong peek");
        assertEq(heap.heapMetadata.rootKey(), 4, "wrong root");
        assertEq(heap.heapMetadata.size(), 2, "wrong size");
        assertEq(heap.heapMetadata.lastNodeKey(), 5, "wrong lastNodeKey");
        assertEq(
            heap.heapMetadata.leftmostNodeKey(), 5, "wrong leftmostNodeKey"
        );
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(4, true)),
            "wrong insertPointer"
        );

        val = heap.pop();
        assertEq(val, 4, "wrong pop");
        assertEq(heap.peek(), 5, "wrong peek");
        assertEq(heap.heapMetadata.rootKey(), 5, "wrong root");
        assertEq(heap.heapMetadata.size(), 1, "wrong size");
        assertEq(heap.heapMetadata.lastNodeKey(), 5, "wrong lastNodeKey");
        assertEq(
            heap.heapMetadata.leftmostNodeKey(), 5, "wrong leftmostNodeKey"
        );
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(5, false)),
            "wrong insertPointer"
        );
    }

    function testSixProperties() public {
        heap.insert(1, 1);
        heap.insert(2, 2);
        heap.insert(3, 3);
        heap.insert(4, 4);
        heap.insert(5, 5);
        heap.insert(6, 6);
        logHeap(heap);
        assertEq(heap.peek(), 1, "wrong peek");
        assertEq(heap.heapMetadata.rootKey(), 1, "wrong root");
        assertEq(heap.heapMetadata.size(), 6, "wrong size");
        assertEq(heap.heapMetadata.lastNodeKey(), 6, "wrong lastNodeKey");
        assertEq(
            heap.heapMetadata.leftmostNodeKey(), 4, "wrong leftmostNodeKey"
        );
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(3, true)),
            "wrong insertPointer"
        );

        uint256 val = heap.pop();
        logHeap(heap);

        // revert();
        assertEq(val, 1, "wrong pop");
        assertEq(heap.peek(), 2, "wrong peek");
        assertEq(heap.heapMetadata.rootKey(), 2, "wrong root");
        assertEq(heap.heapMetadata.size(), 5, "wrong size");
        assertEq(heap.heapMetadata.lastNodeKey(), 5, "wrong lastNodeKey");
        assertEq(
            heap.heapMetadata.leftmostNodeKey(), 6, "wrong leftmostNodeKey"
        );
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(3, false)),
            "wrong insertPointer"
        );
        address(0).call("");

        val = heap.pop();
        logHeap(heap);
        // revert();
        assertEq(val, 2, "wrong pop");
        assertEq(heap.peek(), 3, "wrong peek");
        assertEq(heap.heapMetadata.rootKey(), 3, "wrong root");
        assertEq(heap.heapMetadata.size(), 4, "wrong size");
        assertEq(heap.heapMetadata.lastNodeKey(), 6, "wrong lastNodeKey");
        assertEq(
            heap.heapMetadata.leftmostNodeKey(), 6, "wrong leftmostNodeKey"
        );
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(4, true)),
            "wrong insertPointer"
        );
    }

    function testSevenProperties() public {
        heap.insert(1, 1);
        heap.insert(2, 2);
        heap.insert(3, 3);
        heap.insert(4, 4);
        heap.insert(5, 5);
        heap.insert(6, 6);
        heap.insert(7, 7);

        assertHeap({
            _heap: heap,
            peek: 1,
            root: 1,
            size: 7,
            lastNode: 7,
            leftmostNode: 4,
            pointerKey: 4,
            right: false
        });

        uint256 val = heap.pop();
        assertEq(val, 1);
        assertHeap({
            _heap: heap,
            peek: 2,
            root: 2,
            size: 6,
            lastNode: 6,
            leftmostNode: 7,
            pointerKey: 3,
            right: true
        });

        val = heap.pop();
        assertEq(val, 2);
        assertHeap({
            _heap: heap,
            peek: 3,
            root: 3,
            size: 5,
            lastNode: 5,
            leftmostNode: 7,
            pointerKey: 6,
            right: false
        });

        val = heap.pop();
        assertEq(val, 3);
        assertHeap({
            _heap: heap,
            peek: 4,
            root: 4,
            size: 4,
            lastNode: 7,
            leftmostNode: 7,
            pointerKey: 5,
            right: true
        });

        val = heap.pop();
        assertEq(val, 4);
        assertHeap({
            _heap: heap,
            peek: 5,
            root: 5,
            size: 3,
            lastNode: 6,
            leftmostNode: 7,
            pointerKey: 7,
            right: false
        });

        val = heap.pop();
        assertEq(val, 5);
        assertHeap({
            _heap: heap,
            peek: 6,
            root: 6,
            size: 2,
            lastNode: 7,
            leftmostNode: 7,
            pointerKey: 6,
            right: true
        });

        val = heap.pop();
        assertEq(val, 6);
        assertHeap({
            _heap: heap,
            peek: 7,
            root: 7,
            size: 1,
            lastNode: 7,
            leftmostNode: 7,
            pointerKey: 7,
            right: false
        });
    }

    function testEightProperties() public {
        insertRange(heap, 1, 8);
        assertHeap({
            _heap: heap,
            peek: 1,
            root: 1,
            size: 8,
            lastNode: 8,
            leftmostNode: 8,
            pointerKey: 4,
            right: true
        });

        uint256 val = heap.pop();
        assertEq(val, 1);
        assertHeap({
            _heap: heap,
            peek: 2,
            root: 2,
            size: 7,
            lastNode: 7,
            leftmostNode: 8,
            pointerKey: 8,
            right: false
        });

        val = heap.pop();
        assertEq(val, 2);
        assertHeap({
            _heap: heap,
            peek: 3,
            root: 3,
            size: 6,
            lastNode: 7,
            leftmostNode: 8,
            pointerKey: 6,
            right: true
        });

        val = heap.pop();
        assertEq(val, 3);
        assertHeap({
            _heap: heap,
            peek: 4,
            root: 4,
            size: 5,
            lastNode: 7,
            leftmostNode: 8,
            pointerKey: 6,
            right: false
        });

        val = heap.pop();
        assertEq(val, 4);
        assertHeap({
            _heap: heap,
            peek: 5,
            root: 5,
            size: 4,
            lastNode: 8,
            leftmostNode: 8,
            pointerKey: 7,
            right: true
        });

        val = heap.pop();
        assertEq(val, 5);
        assertHeap({
            _heap: heap,
            peek: 6,
            root: 6,
            size: 3,
            lastNode: 8,
            leftmostNode: 7,
            pointerKey: 7,
            right: false
        });

        val = heap.pop();
        assertEq(val, 6);
        assertHeap({
            _heap: heap,
            peek: 7,
            root: 7,
            size: 2,
            lastNode: 8,
            leftmostNode: 8,
            pointerKey: 7,
            right: true
        });

        val = heap.pop();
        assertEq(val, 7);
        assertHeap({
            _heap: heap,
            peek: 8,
            root: 8,
            size: 1,
            lastNode: 8,
            leftmostNode: 8,
            pointerKey: 8,
            right: false
        });

        val = heap.pop();
        assertEq(val, 8);
        assertHeap({
            _heap: heap,
            peek: 0,
            root: 0,
            size: 0,
            lastNode: 0,
            leftmostNode: 0,
            pointerKey: 0,
            right: false
        });
    }

    function testTenProperties() public {
        insertRange(heap, 1, 10);
        assertHeap({
            _heap: heap,
            peek: 1,
            root: 1,
            size: 10,
            lastNode: 10,
            leftmostNode: 8,
            pointerKey: 5,
            right: true
        });

        uint256 val = heap.pop();
        assertEq(val, 1);
        assertHeap({
            _heap: heap,
            peek: 2,
            root: 2,
            size: 9,
            lastNode: 9,
            leftmostNode: 10,
            pointerKey: 5,
            right: false
        });

        val = heap.pop();
        assertEq(val, 2);
        assertHeap({
            _heap: heap,
            peek: 3,
            root: 3,
            size: 8,
            lastNode: 10,
            leftmostNode: 10,
            pointerKey: 8,
            right: true
        });

        val = heap.pop();
        assertEq(val, 3);
        assertHeap({
            _heap: heap,
            peek: 4,
            root: 4,
            size: 7,
            lastNode: 7,
            leftmostNode: 8,
            pointerKey: 8,
            right: false
        });

        val = heap.pop();
        assertEq(val, 4);
        assertHeap({
            _heap: heap,
            peek: 5,
            root: 5,
            size: 6,
            lastNode: 9,
            leftmostNode: 8,
            pointerKey: 6,
            right: true
        });

        val = heap.pop();
        assertEq(val, 5);
        assertHeap({
            _heap: heap,
            peek: 6,
            root: 6,
            size: 5,
            lastNode: 10,
            leftmostNode: 8,
            pointerKey: 9,
            right: false
        });

        val = heap.pop();
        assertEq(val, 6);
        assertHeap({
            _heap: heap,
            peek: 7,
            root: 7,
            size: 4,
            lastNode: 10,
            leftmostNode: 10,
            pointerKey: 8,
            right: true
        });

        val = heap.pop();
        assertEq(val, 7);
        assertHeap({
            _heap: heap,
            peek: 8,
            root: 8,
            size: 3,
            lastNode: 9,
            leftmostNode: 10,
            pointerKey: 10,
            right: false
        });

        val = heap.pop();
        assertEq(val, 8);
        assertHeap({
            _heap: heap,
            peek: 9,
            root: 9,
            size: 2,
            lastNode: 10,
            leftmostNode: 10,
            pointerKey: 9,
            right: true
        });

        val = heap.pop();
        assertEq(val, 9);
        assertHeap({
            _heap: heap,
            peek: 10,
            root: 10,
            size: 1,
            lastNode: 10,
            leftmostNode: 10,
            pointerKey: 10,
            right: false
        });
    }

    function testInsertSixteen() public {
        heap.insert(1, 1);
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer({_key: 1, _right: false}))
        );
        heap.insert(2, 2);
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer({_key: 1, _right: true}))
        );
        heap.insert(3, 3);
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer({_key: 2, _right: false}))
        );
        heap.insert(4, 4);
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer({_key: 2, _right: true}))
        );
        heap.insert(5, 5);
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer({_key: 3, _right: false}))
        );
        heap.insert(6, 6);
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer({_key: 3, _right: true}))
        );
        heap.insert(7, 7);
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer({_key: 4, _right: false}))
        );
        heap.insert(8, 8);
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer({_key: 4, _right: true}))
        );
        heap.insert(9, 9);
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer({_key: 5, _right: false}))
        );
        heap.insert(10, 10);
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer({_key: 5, _right: true}))
        );
        address(0).call("");
        heap.insert(11, 11);

        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer({_key: 6, _right: false}))
        );
        heap.insert(12, 12);
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer({_key: 6, _right: true}))
        );

        heap.insert(13, 13);
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer({_key: 7, _right: false}))
        );
        heap.insert(14, 14);
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer({_key: 7, _right: true}))
        );

        heap.insert(15, 15);
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer({_key: 8, _right: false}))
        );

        heap.insert(16, 16);
        assertEq(
            Pointer.unwrap(heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer({_key: 8, _right: true}))
        );
    }

    function testTwelveProperties() public {
        insertRange(heap, 1, 12);
        logHeap(heap);
        assertHeap({
            _heap: heap,
            peek: 1,
            root: 1,
            size: 12,
            lastNode: 12,
            leftmostNode: 8,
            pointerKey: 6,
            right: true
        });
    }

    function insertRange(
        MinHeapMap.Heap storage _heap,
        uint256 start,
        uint256 end
    ) internal {
        for (uint256 i = start; i <= end; i++) {
            _heap.insert(i, i);
        }
    }

    function assertHeap(
        MinHeapMap.Heap storage _heap,
        uint256 peek,
        uint256 root,
        uint256 size,
        uint256 lastNode,
        uint256 leftmostNode,
        uint256 pointerKey,
        bool right
    ) internal {
        assertEq(_heap.peek(), peek, "wrong peek");
        assertEq(_heap.heapMetadata.rootKey(), root, "wrong root");
        assertEq(_heap.heapMetadata.size(), size, "wrong size");
        assertEq(
            _heap.heapMetadata.lastNodeKey(), lastNode, "wrong lastNodeKey"
        );
        assertEq(
            _heap.heapMetadata.leftmostNodeKey(),
            leftmostNode,
            "wrong leftmostNodeKey"
        );
        assertEq(
            Pointer.unwrap(_heap.heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(pointerKey, right)),
            "wrong insertPointer"
        );
    }

    function logHeap(MinHeapMap.Heap storage _heap) internal {
        uint256 rootKey = _heap.heapMetadata.rootKey();
        uint256 _nodesSlot = MinHeapMap._nodesSlot(_heap);
        for (uint256 i = rootKey; i < _heap.heapMetadata.size() + rootKey; i++)
        {
            emit NodeLog(
                uint8(i - rootKey + 101),
                bytes32(Node.unwrap(MinHeapMap._get(_nodesSlot, i)))
                );
        }
        emit Space();
    }

    event NodeLog(uint8, bytes32);
    event Space();
}
