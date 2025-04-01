import java.util.*;
 
public class LinkCutTree {
 
    class Node {
        int value;
        Node left, right, parent, pathParent;
 
        Node(int value)
        {
            this.value = value;
            this.left = null;
            this.right = null;
            this.parent = null;
            this.pathParent = null;
        }
    }
 
    private Node[] tree;
 
    LinkCutTree(int n)
    {
        tree = new Node[n];
    }
    // Splay tree methods
    private Node getNode(int i)
    {
        if (i < 0 || i >= tree.length) {
            return null;
        }
        Node x = tree[i];
        if (x == null) {
            x = new Node(i);
            tree[i] = x;
        }
        return x;
    }
 
    private void rotate(Node x)
    {
        Node y = x.parent;
        if (y != null && y.parent != null) {
            x.parent = y.parent;
            if (y.parent.left == y)
                y.parent.left = x;
            else
                y.parent.right = x;
        }
        else
            x.parent = null;
        if (y.left == x) {
            y.left = x.right;
            if (y.left != null)
                y.left.parent = y;
            x.right = y;
        }
        else {
            y.right = x.left;
            if (y.right != null)
                y.right.parent = y;
            x.left = y;
        }
        if (y.pathParent != null) {
            x.pathParent = y.pathParent;
            y.pathParent = null;
        }
    }
 
    private void splay(Node x)
    {
        while (x.parent != null) {
            Node y = x.parent;
            Node z = y.parent;
            if (z != null) {
                if ((z.left == y) == (y.left == x))
                    rotate(y);
                else
                    rotate(x);
            }
            rotate(x);
        }
    }
    // Link-Cut Tree Methods
    public Node access(int i)
    {
        Node x = getNode(i);
        splay(x);
        if (x.right != null) {
            x.right.pathParent = x;
            x.right.parent = null;
            x.right = null;
        }
        Node y = null;
        while (x.pathParent != null) {
            y = x.parent;
            if (y != null) {
                splay(y);
                if (y.right != null) {
                    y.right.pathParent = y;
                    y.right.parent = null;
                }
                x.parent = y;
                y.right = x;
            }
            x.pathParent = null;
            splay(x);
        }
        return y;
    }
 
    public Node findRoot(int i)
    {
        access(i);
        Node x = getNode(i);
        while (x.left != null)
            x = x.left;
        access(x.value);
        return x;
    }
 
    public void link(int x, int y)
    {
        Node ny = getNode(y);
        Node nx = getNode(x);
        access(y);
        access(x);
        nx.parent = ny;
        ny.left = nx;
    }
 
    public void cut(int x)
    {
        access(x);
        Node nx = getNode(x);
        if (nx.left != null) {
            nx.left.parent = null;
            nx.left = null;
        }
    }
    public void print(int ii)
    {
        Node n = getNode(ii);
        System.out.print("(v,l,r,p,pp): (");
        System.out.print(n.value + ", ");
        if (n.left == null) 
            System.out.print(0 + ", ");
        else
            System.out.print(n.left.value + ", ");
        if (n.right == null) 
            System.out.print(0 + ", ");
        else
            System.out.print(n.right.value + ", ");
        if (n.parent == null) 
            System.out.print(0 + ", ");
        else
            System.out.print(n.parent.value + ", ");
        if (n.pathParent == null) 
            System.out.print(0);
        else
            System.out.print(n.pathParent.value);
        System.out.println(")");

         // +  n.parent + n.pathParent);
    }

    // Driver Method
    public static void main(String[] args)
    {
        System.out.println("Hello World!"); //Display the string.
        LinkCutTree tree = new LinkCutTree(6);
 
        // Link nodes to form a tree
        tree.link(2, 1);
        // tree.link(1, 3);
        tree.print(1);
        tree.print(2);
        tree.print(3);


        Node ny = tree.getNode(1);
        Node nx = tree.getNode(3);
        tree.access(1);
        System.out.println("------");
        tree.print(1);
        tree.print(2);
        tree.print(3);
        tree.access(3);
        System.out.println("------");
        tree.print(1);
        tree.print(2);
        tree.print(3);
        nx.parent = ny;
        ny.left = nx;
        System.out.println("------");
        tree.print(1);
        tree.print(2);
        tree.print(3);
        // tree.link(2, 3);
        // tree.link(2, 4);
        // tree.link(4, 5);
 
        // making 3 singleon
        // tree.cut(3);
 
        LinkCutTree.Node root = tree.findRoot(2);
        System.out.println("Root Value for 2: " + root.value);
        tree.access(2);
        tree.print(1);
        tree.print(2);
        tree.print(3);
        root = tree.findRoot(1);
        System.out.println("Root Value for 1: " + root.value);
        tree.print(1);
        tree.print(2);
        tree.print(3);

 
        // root = tree.findRoot(4);
        // System.out.println("Root Value for 4: " + root.value);
 
        // // Making 4 as root
        // tree.access(4);
 
        // root = tree.findRoot(4);
        // System.out.println("New Root Value for 4: " + root.value);
    }
}